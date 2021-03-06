// tclCmdMZ.c --
//
//	This file contains the top-level command routines for most of the Tcl built-in commands whose names begin with the letters
//	M to Z.  It contains only commands in the generic core (i.e. those that don't depend much upon UNIX facilities).
//
// Copyright 1987-1991 Regents of the University of California
// Permission to use, copy, modify, and distribute this software and its documentation for any purpose and without
// fee is hereby granted, provided that the above copyright notice appear in all copies.  The University of California
// makes no representations about the suitability of this software for any purpose.  It is provided "as is" without
// express or implied warranty.

#include "tclInt.h"

// Structure used to hold information about variable traces:
typedef struct {
	int flags;			// Operations for which Tcl command is to be invoked.
	int length;			// Number of non-NULL chars. in command.
	char command[4];	// Space for Tcl command to invoke.  Actual size will be as large as necessary to hold command.  This field must be the last in the structure, so that it can be larger than 4 bytes.
} TraceVarInfo;

// Forward declarations for procedures defined in this file:
static __device__ char *TraceVarProc(ClientData clientData, Tcl_Interp *interp, char *name1, char *name2, int flags);

// Resize the regexp cache
static __device__ void expand_regexp_cache(Interp *iPtr, int newsize)
{
	int i;
	if (newsize > iPtr->num_regexps) {
		// Expand the cache
		iPtr->regexps = (CompiledRegexp *)_reallocFast((char *)iPtr->regexps, sizeof(CompiledRegexp) * newsize);

		// And initialise the new entries
		for (i = iPtr->num_regexps; i < newsize; i++) {
			iPtr->regexps[i].pattern = NULL;
			iPtr->regexps[i].length = -1;
			iPtr->regexps[i].regexp = NULL;
		}
	}
	else if (newsize < iPtr->num_regexps) {
		// Shrink the cache. We just adjust our notion of the size and free any extra entries
		for (i = newsize; i < iPtr->num_regexps; i++) {
			if (iPtr->regexps[i].pattern == NULL) {
				break;
			}
			_freeFast(iPtr->regexps[i].pattern);
			iPtr->regexps[i].pattern = NULL;
			regfree(iPtr->regexps[i].regexp);
			_freeFast((char *)iPtr->regexps[i].regexp);
		}
	}
	iPtr->num_regexps = newsize;
}

/*
*----------------------------------------------------------------------
*
* Tcl_RegexpCmd --
*	This procedure is invoked to process the "regexp" Tcl command. See the user documentation for details on what it does.
*
* Results:
*	A standard Tcl result.
*
* Side effects:
*	See the user documentation.
*
*----------------------------------------------------------------------
*/
__device__ int Tcl_RegexpCmd(ClientData dummy, Tcl_Interp *interp, int argc, const char *args[])
{
	bool noCase = false;
	bool indices = false;
	int i;
	int offset = 0;
	if (argc < 3) {
wrongNumArgs:
		Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " ?-nocase? ?-indices? ?-start offset? exp string ?matchVar? ?subMatchVar ", "subMatchVar ...?\"", (char *)NULL);
		return TCL_ERROR;
	}
	const char **argPtr = args+1;
	argc--;
	while (argc > 0 && argPtr[0][0] == '-') {
		if (!strcmp(argPtr[0], "-indices")) {
			argPtr++;
			argc--;
			indices = true;
		} else if (!strcmp(argPtr[0], "-nocase")) {
			argPtr++;
			argc--;
			noCase = 1;
		} else if (!strcmp(argPtr[0], "-start")) {
			argPtr++;
			argc--;
			if (argc == 0) {
				goto wrongNumArgs;
			}
			if (Tcl_GetInt(interp, argPtr[0], &offset) != TCL_OK) {
				return TCL_ERROR;
			}
			argPtr++;
			argc--;
		} else if (!strcmp(argPtr[0], "-cache")) {
			int newsize;
			argPtr++;
			argc--;
			if (argc == 0) {
				goto wrongNumArgs;
			}
			if (Tcl_GetInt(interp, argPtr[0], &newsize) != TCL_OK) {
				return TCL_ERROR;
			}
			// OK, increase the size of the regexp cache to 'newsize'
			expand_regexp_cache((Interp *)interp, newsize);
			return TCL_OK;
		} else {
			break;
		}
	}
	if (argc < 2) {
		goto wrongNumArgs;
	}

#ifndef REG_ICASE
	if (noCase) {
		Tcl_AppendResult(interp, "sorry, this implementation does not support -nocase", 0);
		return TCL_ERROR;
	}
#endif

	regex_t *regexpPtr = TclCompileRegexp(interp, (char *)argPtr[0], noCase);
	if (regexpPtr == NULL) {
		return TCL_ERROR;
	}

	// If an offset has been specified, adjust for that now. If it points past the end of the string, point to the terminating null
	if (offset) {
		int len = strlen(argPtr[1]);
		if (offset > len) {
			argPtr[1] = argPtr[1] + len;
		} else {
			argPtr[1] = argPtr[1] + offset;
		}
	}

	regmatch_t pmatch[MAX_SUB_MATCHES + 1];
	int match = regexec(regexpPtr, argPtr[1], MAX_SUB_MATCHES, pmatch, 0);
	if (match >= REG_BADPAT) {
		char buf[100];
		regerror(match, regexpPtr, buf, sizeof(buf));
		Tcl_AppendResult(interp, "error while matching pattern: ", buf, (char *)NULL);
		return TCL_ERROR;
	}
	if (match == REG_NOMATCH) {
		interp->result = "0";
		return TCL_OK;
	}

	// If additional variable names have been specified, return index information in those variables.
	argc -= 2;
	if (argc > MAX_SUB_MATCHES) {
		interp->result = "too many substring variables";
		return TCL_ERROR;
	}
	for (i = 0; i < argc; i++) {
		char *result;
		if (pmatch[i].rm_so == -1) {
			if (indices) {
				result = Tcl_SetVar(interp, (char *)argPtr[i+2], "-1 -1", 0);
			} else {
				result = Tcl_SetVar(interp, (char *)argPtr[i+2], "", 0);
			}
		} else {
			if (indices) {
				char info[50];
				sprintf(info, "%d %d", offset + pmatch[i].rm_so, offset + pmatch[i].rm_eo - 1);
				result = Tcl_SetVar(interp, (char *)argPtr[i+2], info, 0);
			} else {
				char *first = (char *)argPtr[1] + pmatch[i].rm_so;
				char *last = (char *)argPtr[1] + pmatch[i].rm_eo;
				char savedChar = *last;
				*last = 0;
				result = Tcl_SetVar(interp, (char *)argPtr[i+2], first, 0);
				*last = savedChar;
			}
		}
		if (result == NULL) {
			Tcl_AppendResult(interp, "couldn't set variable \"", argPtr[i+2], "\"", (char *)NULL);
			return TCL_ERROR;
		}
	}
	interp->result = "1";
	return TCL_OK;
}

/*
*----------------------------------------------------------------------
*
* Tcl_RegsubCmd --
*
*	This procedure is invoked to process the "regsub" Tcl command. See the user documentation for details on what it does.
*
* Results:
*	A standard Tcl result.
*
* Side effects:
*	See the user documentation.
*
*----------------------------------------------------------------------
*/
__device__ int Tcl_RegsubCmd(ClientData dummy, Tcl_Interp *interp, int argc, const char *args[])
{
	if (argc < 5) {
wrongNumArgs:
		Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " ?-nocase? ?-all? exp string subSpec varName\"", (char *)NULL);
		return TCL_ERROR;
	}
	const char **argPtr = args+1;
	argc--;
	bool noCase = false, all = false;
	while (argPtr[0][0] == '-') {
		if (!strcmp(argPtr[0], "-nocase")) {
			argPtr++;
			argc--;
			noCase = true;
		} else if (!strcmp(argPtr[0], "-all")) {
			argPtr++;
			argc--;
			all = true;
		} else {
			break;
		}
	}
	if (argc != 4) {
		goto wrongNumArgs;
	}

#ifndef REG_ICASE
	if (noCase) {
		Tcl_AppendResult(interp, "sorry, this implementation does not support -nocase", 0);
		return TCL_ERROR;
	}
#endif

	regex_t *regexpPtr = TclCompileRegexp(interp, (char *)argPtr[0], noCase);
	if (regexpPtr == NULL) {
		return TCL_ERROR;
	}

	// The following loop is to handle multiple matches within the same source string;  each iteration handles one match and its
	// corresponding substitution.  If "-all" hasn't been specified then the loop body only gets executed once.
	int flags = 0;
	regmatch_t pmatch[MAX_SUB_MATCHES + 1];
	char buf[100];
	int num_matches = 0;
	char *p;
	int result;
	for (p = (char *)argPtr[1]; *p != 0;) {
		int match = regexec(regexpPtr, p, MAX_SUB_MATCHES, pmatch, 0);
		if (match >= REG_BADPAT) {
			regerror(match, regexpPtr, buf, sizeof(buf));
			Tcl_AppendResult(interp, "error while matching pattern: ", buf, (char *)NULL);
			result = TCL_ERROR;
			goto done;
		}
		if (match == REG_NOMATCH) {
			break;
		}

		num_matches++;

		// Copy the portion of the source string before the match to the result variable.
		register char *src = p + pmatch[0].rm_so;
		register char c = *src;
		*src = 0;

		char *newValue = Tcl_SetVar(interp, (char *)argPtr[3], p, flags);
		*src = c;
		flags = TCL_APPEND_VALUE;
		if (newValue == NULL) {
cantSet:
			Tcl_AppendResult(interp, "couldn't set variable \"", argPtr[3], "\"", (char *)NULL);
			result = TCL_ERROR;
			goto done;
		}

		// Append the subSpec argument to the variable, making appropriate substitutions.  This code is a bit hairy because of the backslash
		// conventions and because the code saves up ranges of characters in subSpec to reduce the number of calls to Tcl_SetVar.
		char *firstChar;
		for (src = firstChar = (char *)argPtr[2], c = *src; c != 0; src++, c = *src) {
			int index;
			if (c == '&') {
				index = 0;
			} else if (c == '\\') {
				c = src[1];
				if (c >= '0' && c <= '9') {
					index = c - '0';
				} else if (c == '\\' || c == '&') {
					*src = c;
					src[1] = 0;
					newValue = Tcl_SetVar(interp, (char *)argPtr[3], firstChar, TCL_APPEND_VALUE);
					*src = '\\';
					src[1] = c;
					if (newValue == NULL) {
						goto cantSet;
					}
					firstChar = src+2;
					src++;
					continue;
				} else {
					continue;
				}
			} else {
				continue;
			}
			if (firstChar != src) {
				c = *src;
				*src = 0;
				newValue = Tcl_SetVar(interp, (char *)argPtr[3], firstChar, TCL_APPEND_VALUE);
				*src = c;
				if (newValue == NULL) {
					goto cantSet;
				}
			}
			if (index < MAX_SUB_MATCHES && pmatch[index].rm_so != -1 && pmatch[index].rm_eo != -1) {
				char *first = p + pmatch[index].rm_so;
				char *last = p + pmatch[index].rm_eo;
				char saved = *last;
				*last = 0;
				newValue = Tcl_SetVar(interp, (char *)argPtr[3], first, TCL_APPEND_VALUE);
				*last = saved;
				if (newValue == NULL) {
					goto cantSet;
				}
			}
			if (*src == '\\') {
				src++;
			}
			firstChar = src+1;
		}
		if (firstChar != src) {
			if (Tcl_SetVar(interp, (char *)argPtr[3], firstChar, TCL_APPEND_VALUE) == NULL) {
				goto cantSet;
			}
		}
		p += pmatch[0].rm_eo;
		if (!all || pmatch[0].rm_eo == 0 || argPtr[0][0] == '^') {
			// If we are doing a single match, or we haven't moved with this match or this is an anchored match, we stop
			break;
		}
	}

	// If there were no matches at all, copy the source string to the target and return a "0" result.
	if (flags == 0) {
		if (Tcl_SetVar(interp, (char *)argPtr[3], (char *)argPtr[1], 0) == NULL) {
			goto cantSet;
		}
		interp->result = "0";
		result = TCL_OK;
		goto done;
	}

	// Copy the portion of the string after the last match to the result variable.
	if (*p != 0) {
		if (Tcl_SetVar(interp, (char *)argPtr[3], p, TCL_APPEND_VALUE) == NULL) {
			goto cantSet;
		}
	}
	sprintf(buf, "%d", num_matches);
	Tcl_AppendResult (interp, buf, (char *)NULL);
	result = TCL_OK;

done:
	return result;
}

/*
*----------------------------------------------------------------------
*
* Tcl_RenameCmd --
*
*	This procedure is invoked to process the "rename" Tcl command. See the user documentation for details on what it does.
*
* Results:
*	A standard Tcl result.
*
* Side effects:
*	See the user documentation.
*
*----------------------------------------------------------------------
*/
__device__ int Tcl_RenameCmd(ClientData dummy, Tcl_Interp *interp, int argc, const char *args[])
{
	Interp *iPtr = (Interp *)interp;
	if (argc != 3) {
		Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " oldName newName\"", (char *)NULL);
		return TCL_ERROR;
	}
	if (args[2][0] == '\0') {
		if (Tcl_DeleteCommand(interp, (char *)args[1]) != 0) {
			Tcl_AppendResult(interp, "can't delete \"", args[1], "\": command doesn't exist", (char *)NULL);
			return TCL_ERROR;
		}
		return TCL_OK;
	}
	Tcl_HashEntry *hPtr = Tcl_FindHashEntry(&iPtr->commandTable, (char *)args[2]);
	if (hPtr != NULL) {
		Tcl_AppendResult(interp, "can't rename to \"", args[2], "\": command already exists", (char *)NULL);
		return TCL_ERROR;
	}
	hPtr = Tcl_FindHashEntry(&iPtr->commandTable, (char *)args[1]);
	if (hPtr == NULL) {
		Tcl_AppendResult(interp, "can't rename \"", args[1], "\":  command doesn't exist", (char *)NULL);
		return TCL_ERROR;
	}
	register Command *cmdPtr = (Command *)Tcl_GetHashValue(hPtr);
	Tcl_DeleteHashEntry(hPtr);
	int new_;
	hPtr = Tcl_CreateHashEntry(&iPtr->commandTable, (char *)args[2], &new_);
	Tcl_SetHashValue(hPtr, cmdPtr);
	return TCL_OK;
}

/*
*----------------------------------------------------------------------
*
* Tcl_ReturnCmd --
*	This procedure is invoked to process the "return" Tcl command. See the user documentation for details on what it does.
*
* Results:
*	A standard Tcl result.
*
* Side effects:
*	See the user documentation.
*
*----------------------------------------------------------------------
*/
__device__ int Tcl_ReturnCmd(ClientData dummy, Tcl_Interp *interp, int argc, const char *args[])
{
	if (argc > 2) {
		Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " ?value?\"", (char *)NULL);
		return TCL_ERROR;
	}
	if (argc == 2) {
		Tcl_SetResult(interp, (char *)args[1], TCL_VOLATILE);
	}
	return TCL_RETURN;
}

/*
*----------------------------------------------------------------------
*
* Tcl_ScanCmd --
*	This procedure is invoked to process the "scan" Tcl command. See the user documentation for details on what it does.
*
* Results:
*	A standard Tcl result.
*
* Side effects:
*	See the user documentation.
*
*----------------------------------------------------------------------
*/
__device__ int Tcl_ScanCmd(ClientData dummy, Tcl_Interp *interp, int argc, const char *args[])
{
#define MAX_FIELDS 20
	typedef struct {
		char fmt;			// Format for field.
		int size;			// How many bytes to allow for field.
		char *location;		// Where field will be stored.
	} Field;
	Field fields[MAX_FIELDS];	// Info about all the fields in the format string.
	register Field *curField;
	if (argc < 3) {
		Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " string format ?varName varName ...?\"", (char *)NULL);
		return TCL_ERROR;
	}

	// This procedure operates in four stages:
	// 1. Scan the format string, collecting information about each field.
	// 2. Allocate an array to hold all of the scanned fields.
	// 3. Call sscanf to do all the dirty work, and have it store the parsed fields in the array.
	// 4. Pick off the fields from the array and assign them to variables.
	int arg1Length = (strlen(args[1]) + 4) & ~03; // Number of bytes in argument to be scanned.  This gives an upper limit on string field sizes.
	int numFields = 0; // Number of fields actually specified.
	int totalSize = 0; // Number of bytes needed to store all results combined.
	for (register char *fmt = (char *)args[2]; *fmt != 0; fmt++) {
		if (*fmt != '%') {
			continue;
		}
		fmt++;
		bool suppress; // Current field is assignment- suppressed.
		if (*fmt == '*') {
			suppress = true;
			fmt++;
		} else {
			suppress = false;
		}
		bool widthSpecified = false;
		while (isdigit(*fmt)) {
			widthSpecified = true;
			fmt++;
		}
		if (suppress) {
			continue;
		}
		if (numFields == MAX_FIELDS) {
			interp->result = "too many fields to scan";
			return TCL_ERROR;
		}
		curField = &fields[numFields];
		numFields++;
		switch (*fmt) {
		case 'D':
		case 'O':
		case 'X':
		case 'd':
		case 'o':
		case 'x':
			curField->fmt = 'd';
			curField->size = sizeof(int);
			break;
		case 's':
			curField->fmt = 's';
			curField->size = arg1Length;
			break;
		case 'c':
			if (widthSpecified) {
				interp->result = "field width may not be specified in %c conversion";
				return TCL_ERROR;
			}
			curField->fmt = 'c';
			curField->size = sizeof(int);
			break;
		case 'E':
		case 'F':
			curField->fmt = 'F';
			curField->size = sizeof(double);
			break;
		case 'e':
		case 'f':
			curField->fmt = 'f';
			curField->size = sizeof(float);
			break;
		case '[':
			curField->fmt = 's';
			curField->size = arg1Length;
			do {
				fmt++;
			} while (*fmt != ']');
			break;
		default:
			sprintf(interp->result, "bad scan conversion character \"%c\"", *fmt);
			return TCL_ERROR;
		}
		totalSize += curField->size;
	}

	if (numFields != (argc-3)) {
		interp->result = "different numbers of variable names and field specifiers";
		return TCL_ERROR;
	}

	// Step 2:
	int i;
	char *results = (char *)_allocFast((unsigned)totalSize); // Where scanned output goes.
	for (i = 0, totalSize = 0, curField = fields; i < numFields; i++, curField++) {
		curField->location = results + totalSize;
		totalSize += curField->size;
	}

	// Fill in the remaining fields with NULL;  the only purpose of this is to keep some memory analyzers, like Purify, from complaining.
	for (; i < MAX_FIELDS; i++, curField++) {
		curField->location = NULL;
	}

	// Step 3:
	int numScanned = sscanf(args[1], args[2], // sscanf's result.
		fields[0].location, fields[1].location, fields[2].location,
		fields[3].location, fields[4].location, fields[5].location,
		fields[6].location, fields[7].location, fields[8].location,
		fields[9].location, fields[10].location, fields[11].location,
		fields[12].location, fields[13].location, fields[14].location,
		fields[15].location, fields[16].location, fields[17].location,
		fields[18].location, fields[19].location); 

	// Step 4:
	if (numScanned < numFields) {
		numFields = numScanned;
	}
	for (i = 0, curField = fields; i < numFields; i++, curField++) {
		char string[120];
		switch (curField->fmt) {
		case 'd':
			sprintf(string, "%d", *((int *) curField->location));
			if (Tcl_SetVar(interp, (char *)args[i+3], string, 0) == NULL) {
storeError:
				Tcl_AppendResult(interp, "couldn't set variable \"", args[i+3], "\"", (char *)NULL);
				_freeFast((char *)results);
				return TCL_ERROR;
			}
			break;
		case 'c':
			sprintf(string, "%d", *((char *)curField->location) & 0xff);
			if (Tcl_SetVar(interp, (char *)args[i+3], string, 0) == NULL) {
				goto storeError;
			}
			break;
		case 's':
			if (Tcl_SetVar(interp, (char *)args[i+3], curField->location, 0) == NULL) {
				goto storeError;
			}
			break;
		case 'F':
			sprintf(string, "%g", *((double *)curField->location));
			if (Tcl_SetVar(interp, (char *)args[i+3], string, 0) == NULL) {
				goto storeError;
			}
			break;
		case 'f':
			sprintf(string, "%g", *((float *)curField->location));
			if (Tcl_SetVar(interp, (char *)args[i+3], string, 0) == NULL) {
				goto storeError;
			}
			break;
		}
	}
	_freeFast(results);
	sprintf(interp->result, "%d", numScanned);
	return TCL_OK;
}

/*
*----------------------------------------------------------------------
*
* Tcl_SplitCmd --
*	This procedure is invoked to process the "split" Tcl command. See the user documentation for details on what it does.
*
* Results:
*	A standard Tcl result.
*
* Side effects:
*	See the user documentation.
*
*----------------------------------------------------------------------
*/
__device__ int Tcl_SplitCmd(ClientData dummy, Tcl_Interp *interp, int argc, const char *args[])
{
	char *splitChars;
	if (argc == 2) {
		splitChars = " \n\t\r";
	} else if (argc == 3) {
		splitChars = (char *)args[2];
	} else {
		Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " string ?splitChars?\"", (char *)NULL);
		return TCL_ERROR;
	}
	// Handle the special case of splitting on every character.
	register char *p;
	if (*splitChars == 0) {
		char string[2];
		string[1] = 0;
		for (p = (char *)args[1]; *p != 0; p++) {
			string[0] = *p;
			Tcl_AppendElement(interp, string, 0);
		}
		return TCL_OK;
	}
	// Normal case: split on any of a given set of characters. Discard instances of the split characters.
	char *elementStart;
	for (p = elementStart = (char *)args[1]; *p != 0; p++) {
		char c = *p;
		for (register char *p2 = splitChars; *p2 != 0; p2++) {
			if (*p2 == c) {
				*p = 0;
				Tcl_AppendElement(interp, elementStart, 0);
				*p = c;
				elementStart = p+1;
				break;
			}
		}
	}
	if (p != args[1]) {
		Tcl_AppendElement(interp, elementStart, 0);
	}
	return TCL_OK;
}

/*
*----------------------------------------------------------------------
*
* Tcl_StringCmd --
*	This procedure is invoked to process the "string" Tcl command. See the user documentation for details on what it does.
*
* Results:
*	A standard Tcl result.
*
* Side effects:
*	See the user documentation.
*
*----------------------------------------------------------------------
*/
__device__ int Tcl_StringCmd(ClientData dummy, Tcl_Interp *interp, int argc, const char *args[])
{
	if (argc < 2) {
		Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " option arg ?arg ...?\"", (char *)NULL);
		return TCL_ERROR;
	}
	register char c = args[1][0];
	int length = strlen(args[1]);
	int match;
	register char *p;
	int first, left = 0, right = 0;
	if (c == 'c' && !strncmp(args[1], "compare", length)) {
		if (argc != 4) {
			Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " compare string1 string2\"", (char *)NULL);
			return TCL_ERROR;
		}
		match = strcmp(args[2], args[3]);
		if (match > 0) {
			interp->result = "1";
		} else if (match < 0) {
			interp->result = "-1";
		} else {
			interp->result = "0";
		}
		return TCL_OK;
	} else if (!strcmp(args[1], "equal")) {
		if (argc != 4) {
			Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " equal string1 string2\"", (char *)NULL);
			return TCL_ERROR;
		}
		match = strcmp(args[2], args[3]);
		if (match == 0) {
			interp->result = "1";
		} else {
			interp->result = "0";
		}
		return TCL_OK;
	} else if (c == 'f' && (!strncmp(args[1], "first", length))) {
		if (argc != 4) {
			Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " first string1 string2\"", (char *)NULL);
			return TCL_ERROR;
		}
		first = 1;
firstLast:
		match = -1;
		c = *args[2];
		length = strlen(args[2]);
		for (p = (char *)args[3]; *p != 0; p++) {
			if (*p != c) {
				continue;
			}
			if (!strncmp(args[2], p, length)) {
				match = (int)(p-args[3]);
				if (first) {
					break;
				}
			}
		}
		sprintf(interp->result, "%d", match);
		return TCL_OK;
	} else if (c == 'i' && !strncmp(args[1], "index", length)) {
		int index;
		if (argc != 4) {
			Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " index string charIndex\"", (char *)NULL);
			return TCL_ERROR;
		}
		if (Tcl_GetInt(interp, args[3], &index) != TCL_OK) {
			return TCL_ERROR;
		}
		if (index >= 0 && index < strlen(args[2])) {
			interp->result[0] = args[2][index];
			interp->result[1] = 0;
		}
		return TCL_OK;
	} else if (c == 'l' && !strncmp(args[1], "last", length) && length >= 2) {
		if (argc != 4) {
			Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " last string1 string2\"", (char *)NULL);
			return TCL_ERROR;
		}
		first = 0;
		goto firstLast;
	} else if (c == 'l' && !strncmp(args[1], "length", length) && length >= 2) {
		if (argc != 3) {
			Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " length string\"", (char *)NULL);
			return TCL_ERROR;
		}
		sprintf(interp->result, "%d", (int)strlen(args[2]));
		return TCL_OK;
	} else if (c == 'm' && !strncmp(args[1], "match", length)) {
		if (argc != 4) {
			Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " match pattern string\"", (char *)NULL);
			return TCL_ERROR;
		}
		if (Tcl_StringMatch((char *)args[3], (char *)args[2]) != 0) {
			interp->result = "1";
		} else {
			interp->result = "0";
		}
		return TCL_OK;
	} else if (c == 'r' && !strncmp(args[1], "range", length)) {
		if (argc != 5) {
			Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " range string first last\"", (char *)NULL);
			return TCL_ERROR;
		}
		int stringLength = strlen(args[2]);
		int first, last;
		if (Tcl_GetInt(interp, args[3], &first) != TCL_OK) {
			return TCL_ERROR;
		}
		if (*args[4] == 'e' && !strncmp(args[4], "end", strlen(args[4]))) {
			last = stringLength-1;
		} else {
			if (Tcl_GetInt(interp, args[4], &last) != TCL_OK) {
				Tcl_ResetResult(interp);
				Tcl_AppendResult(interp, "expected integer or \"end\" but got \"", args[4], "\"", (char *)NULL);
				return TCL_ERROR;
			}
		}
		if (first < 0) {
			first = 0;
		}
		if (last >= stringLength) {
			last = stringLength-1;
		}
		if (last >= first) {
			p = (char *)args[2] + last + 1;
			char saved = *p;
			*p = 0;
			Tcl_SetResult(interp, (char *)args[2] + first, TCL_VOLATILE);
			*p = saved;
		}
		return TCL_OK;
	} else if (!strcmp(args[1], "repeat")) {
		if (argc != 4) {
			Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " repeat string count\"", (char *)NULL);
			return TCL_ERROR;
		}
		int count;
		if (Tcl_GetInt(interp, args[3], &count) != TCL_OK) {
			Tcl_ResetResult(interp);
			Tcl_AppendResult(interp, "expected integer but got \"", args[3], "\"", (char *)NULL);
			return TCL_ERROR;
		}
		Tcl_ResetResult(interp);
		while (count-- > 0) {
			Tcl_AppendResult(interp, args[2], (char *)NULL);
		}
		return TCL_OK;
	} else if (c == 't' && !strncmp(args[1], "tolower", length) && length >= 3) {
		if (argc != 3) {
			Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " tolower string\"", (char *)NULL);
			return TCL_ERROR;
		}
		Tcl_SetResult(interp, (char *)args[2], TCL_VOLATILE);
		for (p = interp->result; *p != 0; p++) {
			if (isupper(*p)) {
				*p = _tolower(*p);
			}
		}
		return TCL_OK;
	} else if (c == 't' && !strncmp(args[1], "toupper", length) && length >= 3) {
		if (argc != 3) {
			Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " toupper string\"", (char *)NULL);
			return TCL_ERROR;
		}
		Tcl_SetResult(interp, (char *)args[2], TCL_VOLATILE);
		for (p = interp->result; *p != 0; p++) {
			if (islower(*p)) {
				*p = _toupper(*p);
			}
		}
		return TCL_OK;
	} else if (c == 't' && !strncmp(args[1], "trim", length) && length == 4) {
		left = right = 1;
		register char *checkPtr;
trim:
		char *trimChars;
		if (argc == 4) {
			trimChars = (char *)args[3];
		} else if (argc == 3) {
			trimChars = " \t\n\r";
		} else {
			Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " ", args[1], " string ?chars?\"", (char *)NULL);
			return TCL_ERROR;
		}
		p = (char *)args[2];
		if (left) {
			for (c = *p; c != 0; p++, c = *p) {
				for (checkPtr = trimChars; *checkPtr != c; checkPtr++) {
					if (*checkPtr == 0) {
						goto doneLeft;
					}
				}
			}
		}
doneLeft:
		Tcl_SetResult(interp, p, TCL_VOLATILE);
		if (right) {
			p = interp->result + strlen(interp->result) - 1;
			char *donePtr = &interp->result[-1];
			for (c = *p; p != donePtr; p--, c = *p) {
				for (checkPtr = trimChars; *checkPtr != c; checkPtr++) {
					if (*checkPtr == 0) {
						goto doneRight;
					}
				}
			}
doneRight:
			p[1] = 0;
		}
		return TCL_OK;
	} else if (c == 't' && !strncmp(args[1], "trimleft", length) && length > 4) {
		left = 1;
		args[1] = "trimleft";
		goto trim;
	} else if (c == 't' && !strncmp(args[1], "trimright", length) && length > 4) {
		right = 1;
		args[1] = "trimright";
		goto trim;
	} else {
		Tcl_AppendResult(interp, "bad option \"", args[1], "\": should be compare, first, index, last, length, match, ", "range, tolower, toupper, trim, trimleft, or trimright", (char *)NULL);
		return TCL_ERROR;
	}
}

/*
*----------------------------------------------------------------------
*
* Tcl_TraceCmd --
*	This procedure is invoked to process the "trace" Tcl command. See the user documentation for details on what it does.
*
* Results:
*	A standard Tcl result.
*
* Side effects:
*	See the user documentation.
*
*----------------------------------------------------------------------
*/
__device__ int Tcl_TraceCmd(ClientData dummy, Tcl_Interp *interp, int argc, const char *args[])
{
	if (argc < 2) {
		Tcl_AppendResult(interp, "too few args: should be \"", args[0], " option [arg arg ...]\"", (char *)NULL);
		return TCL_ERROR;
	}
	char c = args[1][1];
	int length = strlen(args[1]);
	char *p;
	if (c == 'a' && !strncmp(args[1], "variable", length) && length >= 2) {
		if (argc != 5) {
			Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " variable name ops command\"", (char *)NULL);
			return TCL_ERROR;
		}
		int flags = 0;
		for (p = (char *)args[3] ; *p != 0; p++) {
			if (*p == 'r') {
				flags |= TCL_TRACE_READS;
			} else if (*p == 'w') {
				flags |= TCL_TRACE_WRITES;
			} else if (*p == 'u') {
				flags |= TCL_TRACE_UNSETS;
			} else {
				goto badOps;
			}
		}
		if (flags == 0) {
			goto badOps;
		}
		length = strlen(args[4]);
		TraceVarInfo *tvarPtr = (TraceVarInfo *)_allocFast((unsigned)(sizeof(TraceVarInfo) - sizeof(tvarPtr->command) + length + 1));
		tvarPtr->flags = flags;
		tvarPtr->length = length;
		flags |= TCL_TRACE_UNSETS;
		strcpy(tvarPtr->command, args[4]);
		if (Tcl_TraceVar(interp, (char *)args[2], flags, TraceVarProc, (ClientData)tvarPtr) != TCL_OK) {
			_freeFast((char *)tvarPtr);
			return TCL_ERROR;
		}
	} else if (c == 'd' && !strncmp(args[1], "vdelete", length) && length >= 2) {
		if (argc != 5) {
			Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " vdelete name ops command\"", (char *)NULL);
			return TCL_ERROR;
		}
		int flags = 0;
		for (p = (char *)args[3] ; *p != 0; p++) {
			if (*p == 'r') {
				flags |= TCL_TRACE_READS;
			} else if (*p == 'w') {
				flags |= TCL_TRACE_WRITES;
			} else if (*p == 'u') {
				flags |= TCL_TRACE_UNSETS;
			} else {
				goto badOps;
			}
		}
		if (flags == 0) {
			goto badOps;
		}
		// Search through all of our traces on this variable to see if there's one with the given command.  If so, then delete the first one that matches.
		length = strlen(args[4]);
		ClientData clientData = 0;
		while ((clientData = Tcl_VarTraceInfo(interp, (char *)args[2], 0, TraceVarProc, clientData)) != 0) {
			TraceVarInfo *tvarPtr = (TraceVarInfo *)clientData;
			if (tvarPtr->length == length && tvarPtr->flags == flags && !strncmp(args[4], tvarPtr->command, length)) {
				Tcl_UntraceVar(interp, (char *)args[2], flags | TCL_TRACE_UNSETS, TraceVarProc, clientData);
				_freeFast((char *)tvarPtr);
				break;
			}
		}
	} else if (c == 'i' && !strncmp(args[1], "vinfo", length) && length >= 2) {
		if (argc != 3) {
			Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " vinfo name\"", (char *)NULL);
			return TCL_ERROR;
		}
		char *prefix = "{";
		char ops[4];
		ClientData clientData = 0;
		while ((clientData = Tcl_VarTraceInfo(interp, (char *)args[2], 0, TraceVarProc, clientData)) != 0) {
			TraceVarInfo *tvarPtr = (TraceVarInfo *)clientData;
			p = ops;
			if (tvarPtr->flags & TCL_TRACE_READS) {
				*p = 'r';
				p++;
			}
			if (tvarPtr->flags & TCL_TRACE_WRITES) {
				*p = 'w';
				p++;
			}
			if (tvarPtr->flags & TCL_TRACE_UNSETS) {
				*p = 'u';
				p++;
			}
			*p = '\0';
			Tcl_AppendResult(interp, prefix, (char *)NULL);
			Tcl_AppendElement(interp, ops, 1);
			Tcl_AppendElement(interp, tvarPtr->command, 0);
			Tcl_AppendResult(interp, "}", (char *)NULL);
			prefix = " {";
		}
	} else {
		Tcl_AppendResult(interp, "bad option \"", args[1], "\": should be variable, vdelete, or vinfo", (char *)NULL);
		return TCL_ERROR;
	}
	return TCL_OK;

badOps:
	Tcl_AppendResult(interp, "bad operations \"", args[3], "\": should be one or more of rwu", (char *)NULL);
	return TCL_ERROR;
}

/*
*----------------------------------------------------------------------
*
* TraceVarProc --
*	This procedure is called to handle variable accesses that have been traced using the "trace" command.
*
* Results:
*	Normally returns NULL.  If the trace command returns an error, then this procedure returns an error string.
*
* Side effects:
*	Depends on the command associated with the trace.
*
*----------------------------------------------------------------------
*/
#undef STATIC_SIZE
static __device__ char *TraceVarProc(ClientData clientData, Tcl_Interp *interp, char *name1, char *name2, int flags)
{
	TraceVarInfo *tvarPtr = (TraceVarInfo *)clientData;
#define STATIC_SIZE 199
	char *result = NULL;
	if ((tvarPtr->flags & flags) && !(flags & TCL_INTERP_DESTROYED)) {
		// Generate a command to execute by appending list elements for the two variable names and the operation.
		// The five extra characters are for three space, the opcode character, and the terminating null.
		if (name2 == NULL) {
			name2 = "";
		}
		int flags1, flags2;
		int cmdLength = tvarPtr->length + Tcl_ScanElement(name1, &flags1) + Tcl_ScanElement(name2, &flags2) + 5;
		char *cmdPtr;
		char staticSpace[STATIC_SIZE+1];
		if (cmdLength < STATIC_SIZE) {
			cmdPtr = staticSpace;
		} else {
			cmdPtr = (char *)_allocFast((unsigned)cmdLength);
		}
		char *p = cmdPtr;
		strcpy(p, tvarPtr->command);
		p += tvarPtr->length;
		*p = ' ';
		p++;
		p += Tcl_ConvertElement(name1, p, flags1);
		*p = ' ';
		p++;
		p += Tcl_ConvertElement(name2, p, flags2);
		*p = ' ';
		if (flags & TCL_TRACE_READS) {
			p[1] = 'r';
		} else if (flags & TCL_TRACE_WRITES) {
			p[1] = 'w';
		} else if (flags & TCL_TRACE_UNSETS) {
			p[1] = 'u';
		}
		p[2] = '\0';

		// Execute the command.  Be careful to save and restore the result from the interpreter used for the command.
		Interp dummy;
		if (interp->freeProc == 0) {
			dummy.freeProc = (Tcl_FreeProc *)0;
			dummy.result = "";
			Tcl_SetResult((Tcl_Interp *)&dummy, interp->result, TCL_VOLATILE);
		} else {
			dummy.freeProc = interp->freeProc;
			dummy.result = interp->result;
		}
		int code = Tcl_Eval(interp, cmdPtr, 0, (char **)NULL);
		if (cmdPtr != staticSpace) {
			_freeFast(cmdPtr);
		}
		if (code != TCL_OK) {
			result = "access disallowed by trace command";
			Tcl_ResetResult(interp); // Must clear error state.
		}
		Tcl_FreeResult(interp);
		interp->result = dummy.result;
		interp->freeProc = dummy.freeProc;
	}
	if (flags & TCL_TRACE_DESTROYED) {
		_freeFast((char *)tvarPtr);
	}
	return result;
}

/*
*----------------------------------------------------------------------
*
* Tcl_WhileCmd --
*	This procedure is invoked to process the "while" Tcl command. See the user documentation for details on what it does.
*
* Results:
*	A standard Tcl result.
*
* Side effects:
*	See the user documentation.
*
*----------------------------------------------------------------------
*/
__device__ int Tcl_WhileCmd(ClientData dummy, Tcl_Interp *interp, int argc, const char *args[])
{
	if (argc != 3) {
		Tcl_AppendResult(interp, "wrong # args: should be \"", args[0], " test command\"", (char *)NULL);
		return TCL_ERROR;
	}
	int result;
	while (true) {
		int value;
		result = Tcl_ExprBoolean(interp, (char *)args[1], &value);
		if (result != TCL_OK) {
			return result;
		}
		if (!value) {
			break;
		}
		result = Tcl_Eval(interp, (char *)args[2], 0, (char **)NULL);
		if (result == TCL_CONTINUE) {
			result = TCL_OK;
		} else if (result != TCL_OK) {
			if (result == TCL_ERROR) {
				char msg[60];
				sprintf(msg, "\n    (\"while\" body line %d)", interp->errorLine);
				Tcl_AddErrorInfo(interp, msg);
			}
			break;
		}
	}
	if (result == TCL_BREAK) {
		result = TCL_OK;
	}
	if (result == TCL_OK) {
		Tcl_ResetResult(interp);
	}
	return result;
}
