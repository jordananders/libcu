#include "stdafx.h"

using namespace System;
using namespace System::Text;
using namespace System::Collections::Generic;
using namespace Microsoft::VisualStudio::TestTools::UnitTesting;

cudaError_t stdlib_test1();
cudaError_t stdlib_strtol();
cudaError_t stdlib_strtoq();
namespace libcutests
{
	[TestClass]
	public ref class stdlibTest
	{
	private:
		TestContext^ _testCtx;

	public: 
		property Microsoft::VisualStudio::TestTools::UnitTesting::TestContext^ TestContext
		{
			Microsoft::VisualStudio::TestTools::UnitTesting::TestContext^ get() { return _testCtx; }
			System::Void set(Microsoft::VisualStudio::TestTools::UnitTesting::TestContext^ value) { _testCtx = value; }
		}

#pragma region Initialize/Cleanup
		[ClassInitialize()] static void ClassInitialize(Microsoft::VisualStudio::TestTools::UnitTesting::TestContext^ testContext) { allClassInitialize(); }
		[ClassCleanup()] static void ClassCleanup() { allClassCleanup(); }
		[TestInitialize()]void TestInitialize() { allTestInitialize(); }
		[TestCleanup()] void TestCleanup() { allTestCleanup(); }
#pragma endregion 

		[TestMethod, TestCategory("core")] void stdlib_test1() { Assert::AreEqual("no error", gcnew String(cudaGetErrorString(::stdlib_test1()))); }
		[TestMethod, TestCategory("core")] void stdlib_strtol() { Assert::AreEqual("no error", gcnew String(cudaGetErrorString(::stdlib_strtol()))); }
		[TestMethod, TestCategory("core")] void stdlib_strtoq() { Assert::AreEqual("no error", gcnew String(cudaGetErrorString(::stdlib_strtoq()))); }
	};
}
