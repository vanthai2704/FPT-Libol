using System;
using System.Collections.Generic;
using Libol.Models;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace FlibUnitTest.FlibReportUnitTests
{
    [TestClass]
    public class UnitTest3
    {
        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_Successfully1()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("SE04480", "", "", 81, "GT/", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(6, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_Successfully2()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("SE04480", "", "", 81, "TK/", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_Successfully3()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("SE04480", "", "", 81, "0", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(6, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_Successfully4()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("SE04480", "", "", 0, "0", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(17, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_Successfully5()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("SE04480", "", "", 0, "0", "", "01/01/2015", "01/01/2019", "", "", "", 1);
            // Assert
            Assert.AreEqual(14, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_Successfully6()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("SE04480", "", "", 0, "0", "", "", "", "01/01/2015", "01/01/2019", "", 1);
            // Assert
            Assert.AreEqual(17, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_Successfully7()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("", "FPT070013581", "", 0, "0", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(95, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_Successfully8()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("", "", "TK/CNTT000038", 0, "0", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(21, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_UT_Fail1()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("SE04480", "", "", -81, "TK/", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_UT_Fail2()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("SE04480", "", "", 81, "-TK", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_UT_Fail3()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("-SE04480", "", "", 81, "TK/", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_UT_Fail4()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("SE04480", "", "", 81, "TK/", "-1", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_UT_Fail5()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("SE04480", "", "", 0, "0", "", "01/01/2019", "01/01/2015", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_UT_Fail6()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("SE04480", "", "", 0, "0", "", "", "", "01/01/2019", "01/01/2015", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_UT_Fail7()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("", "-FPT070013581", "", 0, "0", "", "", "", "01/01/2019", "01/01/2015", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_LOAN_INFOR_LIST_UT_Fail8()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_LOANINFOR_Result> actual = cb.GET_PATRON_LOAN_INFOR_LIST("", "", "-TK/CNTT000038", 0, "0", "", "", "", "01/01/2019", "01/01/2015", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Successfully1()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("SE01989", "", "", 0, "0", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(155, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Successfully2()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("", "", "TK/CNTT000038", 0, "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(3, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Successfully3()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("", "FPT070013581", "", 0, "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(81, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Successfully4()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("", "", "", 81, "TK/", "103", "01/01/2019", "01/08/2019", "", "", 1);
            // Assert
            Assert.AreEqual(20, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Successfully5()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("", "", "", 81, "TK/", "103", "", "", "01/01/2015", "01/08/2015", 1);
            // Assert
            Assert.AreEqual(14, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Successfully6()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("se04477", "", "", 81, "0", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(11, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Successfully7()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("", "FPT070013581", "", 81, "0", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(58, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Successfully8()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("", "", "TK/XHHL003318", 81, "0", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(3, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Fail1()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("SE04477", "", "", 81, "-TK", "103", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Fail2()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("-SE04477", "", "", 81, "TK/", "103", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Fail3()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("SE04477", "", "", -81, "TK/", "103", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Fail4()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("", "AAAAAA", "", 81, "TK/", "103", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Fail5()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("", "", "AAAAAA", 81, "TK/", "103", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Fail6()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("", "", "", 81, "TK/", "-103", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Fail7()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("", "", "", 81, "TK/", "103", "01/01/2019", "01/01/2018", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_LOAN_INFOR_LIST_Fail8()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST("", "", "", 81, "TK/", "103", "", "", "01/01/2019", "01/01/2018", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_ONLOAN_INFOR_LIST_Successfully1()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_ONLOANINFOR_Result> actual = cb.GET_PATRON_ONLOAN_INFOR_LIST("HE140133", "", "", 81, "GT/", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(6, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_ONLOAN_INFOR_LIST_Successfully2()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_ONLOANINFOR_Result> actual = cb.GET_PATRON_ONLOAN_INFOR_LIST("SE04480", "", "", 81, "TK/", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_ONLOAN_INFOR_LIST_Successfully3()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_ONLOANINFOR_Result> actual = cb.GET_PATRON_ONLOAN_INFOR_LIST("HE140133", "", "", 81, "0", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(6, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_ONLOAN_INFOR_LIST_Successfully4()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_ONLOANINFOR_Result> actual = cb.GET_PATRON_ONLOAN_INFOR_LIST("HE140133", "", "", 0, "", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(7, actual.Count);
        }        

        [TestMethod]
        public void GET_PATRON_ONLOAN_INFOR_LIST_Successfully7()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_ONLOANINFOR_Result> actual = cb.GET_PATRON_ONLOAN_INFOR_LIST("", "FPT070013581", "", 0, "", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(1, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_ONLOAN_INFOR_LIST_Successfully8()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_ONLOANINFOR_Result> actual = cb.GET_PATRON_ONLOAN_INFOR_LIST("", "", "GT/TNHL000925", 0, "", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(1, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_ONLOAN_INFOR_LIST_UT_Fail1()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_ONLOANINFOR_Result> actual = cb.GET_PATRON_ONLOAN_INFOR_LIST("SE04480", "", "", -81, "TK/", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_ONLOAN_INFOR_LIST_UT_Fail2()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_ONLOANINFOR_Result> actual = cb.GET_PATRON_ONLOAN_INFOR_LIST("SE04480", "", "", 81, "-TK", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_ONLOAN_INFOR_LIST_UT_Fail3()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_ONLOANINFOR_Result> actual = cb.GET_PATRON_ONLOAN_INFOR_LIST("-SE04480", "", "", 81, "TK/", "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_ONLOAN_INFOR_LIST_UT_Fail4()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_ONLOANINFOR_Result> actual = cb.GET_PATRON_ONLOAN_INFOR_LIST("SE04480", "", "", 81, "TK/", "-1", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_ONLOAN_INFOR_LIST_UT_Fail5()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_ONLOANINFOR_Result> actual = cb.GET_PATRON_ONLOAN_INFOR_LIST("SE04480", "", "", 0, "0", "", "01/01/2019", "01/01/2015", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_ONLOAN_INFOR_LIST_UT_Fail6()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_ONLOANINFOR_Result> actual = cb.GET_PATRON_ONLOAN_INFOR_LIST("SE04480", "", "", 0, "0", "", "", "", "01/01/2019", "01/01/2015", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_ONLOAN_INFOR_LIST_UT_Fail7()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_ONLOANINFOR_Result> actual = cb.GET_PATRON_ONLOAN_INFOR_LIST("", "-FPT070013581", "", 0, "0", "", "", "", "01/01/2019", "01/01/2015", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_ONLOAN_INFOR_LIST_UT_Fail8()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_ONLOANINFOR_Result> actual = cb.GET_PATRON_ONLOAN_INFOR_LIST("", "", "-TK/CNTT000038", 0, "0", "", "", "", "01/01/2019", "01/01/2015", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_ONLOAN_INFOR_LIST_Successfully1()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST("HE140133", "", "", 0, "0", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_ONLOAN_INFOR_LIST_Successfully2()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST("", "", "GT/TNHL000925", 0, "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_ONLOAN_INFOR_LIST_Successfully3()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST("", "FPT070013581", "", 0, "", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_ONLOAN_INFOR_LIST_Successfully4()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST("", "", "", 81, "TK/", "103", "01/01/2018", "01/08/2019", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }


        [TestMethod]
        public void GET_PATRON_RENEW_ONLOAN_INFOR_LIST_Successfully6()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST("se04477", "", "", 81, "0", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_ONLOAN_INFOR_LIST_Successfully7()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST("", "FPT070013581", "", 81, "0", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_ONLOAN_INFOR_LIST_Successfully8()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST("", "", "GT/TNHL000921", 81, "0", "", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(4, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_ONLOAN_INFOR_LIST_Fail1()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST("SE04477", "", "", 81, "-TK", "103", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_ONLOAN_INFOR_LIST_Fail2()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST("-SE04477", "", "", 81, "TK/", "103", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_ONLOAN_INFOR_LIST_Fail3()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST("SE04477", "", "", -81, "TK/", "103", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_ONLOAN_INFOR_LIST_Fail4()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST("", "AAAAAA", "", 81, "TK/", "103", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_ONLOAN_INFOR_LIST_Fail5()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST("", "", "AAAAAA", 81, "TK/", "103", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_ONLOAN_INFOR_LIST_Fail6()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST("", "", "", 81, "TK/", "-103", "", "", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

        [TestMethod]
        public void GET_PATRON_RENEW_ONLOAN_INFOR_LIST_Fail7()
        {
            // Arrange
            CirculationBusiness cb = new CirculationBusiness();
            // Act
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> actual = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST("", "", "", 81, "TK/", "103", "01/01/2019", "01/01/2018", "", "", 1);
            // Assert
            Assert.AreEqual(0, actual.Count);
        }

    }
}
