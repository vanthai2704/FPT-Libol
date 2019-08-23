using System;
using System.Transactions;
using System.Web.Mvc;
using Libol.Controllers;
using Libol.Models;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace FlibUnitTest.FlibOrientationUnitTests
{
    [TestClass]
    public class UnitTest1
    {
        [TestMethod]
        public void TestMethod1()
        {
        }
    }

    [TestClass]
    public class LoginControllerTests
    {

        [TestMethod]
        public void Index()
        {
            // Arrange
            LoginController controller = new LoginController();
            // Act
            ViewResult result = controller.Index() as ViewResult;
            // Assert
            Assert.IsNotNull(result);
        }
    }

    [TestClass]
    public class ManagementControllerTests
    {
        [TestMethod]
        public void TestMethod1()
        {
            Assert.AreEqual(1, 1);
        }
    }

    [TestClass]
    public class PatronControllerTests
    {
        [TestMethod]
        public void Index()
        {
            // Arrange
            PatronController controller = new PatronController();
            // Act
            ViewResult result = controller.PatronProfile() as ViewResult;
            // Assert
            Assert.IsNotNull(result);
        }
    }

    [TestClass]
    public class CatalogueControllerTests
    {
        [TestMethod]
        public void Index()
        {
            // Arrange
            CatalogueController controller = new CatalogueController();
            // Act
            ViewResult result = controller.MainTab() as ViewResult;
            // Assert
            Assert.IsNotNull(result);
        }
    }

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

    [TestClass]
    public class CheckInControllerTests
    {
        [TestMethod]
        public void Index()
        {
            // Arrange
            CheckInController controller = new CheckInController();
            // Act
            ViewResult result = controller.Index("") as ViewResult;
            // Assert
            Assert.IsNotNull(result);
        }
    }
}
