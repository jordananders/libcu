#include "stdafx.h"

using namespace System;
using namespace System::Text;
using namespace System::Collections::Generic;
using namespace Microsoft::VisualStudio::TestTools::UnitTesting;

cudaError_t time_test1();
namespace libcutests
{
	[TestClass]
	public ref class timeTest
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
		[TestInitialize()] void TestInitialize() { allTestInitialize(); }
		[TestCleanup()] void TestCleanup() { allTestCleanup(); }
#pragma endregion 

		[TestMethod, TestCategory("core")] void time_test1() { Assert::AreEqual("no error", gcnew String(cudaGetErrorString(::time_test1()))); }
	};
}
