using System;
using System.Web.Mvc;
using Libol.Controllers;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace FlibUnitTest.FlibOrientationUnitTests
{

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
}
