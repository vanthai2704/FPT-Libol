using System;
using System.Transactions;
using System.Web.Mvc;
using Libol.Controllers;
using Libol.Models;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace FlibUnitTest.FlibOrientationUnitTests
{
    

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

}
