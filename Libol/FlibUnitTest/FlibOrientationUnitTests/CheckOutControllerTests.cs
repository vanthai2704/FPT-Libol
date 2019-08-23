using System;
using System.Transactions;
using System.Web.Mvc;
using Libol.Controllers;
using Libol.Models;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace FlibUnitTest.FlibOrientationUnitTests
{
    [TestClass]
    public class CheckOutControllerTests
    {
        [TestMethod]
        public void TestMethod1()
        {
            using (TransactionScope transaction = new TransactionScope())
            {
                LibolEntities db = new LibolEntities();
                CheckOutController checkOutController = new CheckOutController();
                PartialViewResult result = checkOutController.CheckOutCardInfo("900047107");
                Assert.AreEqual("_showPatronInfo", result.ViewName);
            }

        }
        [TestMethod]
        public void TestMethod2()
        {
            using (TransactionScope transaction = new TransactionScope())
            {
                LibolEntities db = new LibolEntities();
                CheckOutController checkOutController = new CheckOutController();
                PartialViewResult result = checkOutController.CheckOut("900047107", "", 1, 0, "aaa", "2019-08-22", true);
                Assert.AreEqual("ĐKCB không đúng", result.ViewName);
                transaction.Complete();
            }

        }
    }
}
