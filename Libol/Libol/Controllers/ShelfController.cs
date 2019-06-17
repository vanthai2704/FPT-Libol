using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.Models;

namespace Libol.Controllers
{
    public class ShelfController : BaseController
    {
        LibolEntities libol = new LibolEntities();
        // GET: Shelf
        public ActionResult Index()
        {
            //LibolEntities libol = new LibolEntities();
            ////get list Nguon Bo Sung
            //var getListDB = libol.ACQ_ACQUIRE_SOURCE.ToList();
            //SelectList list = new SelectList(getListDB, "ID", "Source");
            //ViewBag.listDemo = list;

            LoadListNBS();
            LoadListKTL();
            LoadListCurrency();

            // get list Kieu tu lieu
            //var getlistKTL = libol.CIR_LOAN_TYPE.ToList();
            //SelectList listKTL = new SelectList(getlistKTL, "ID", "LoanType");
            //ViewBag.listKTL = listKTL;

            return View();
        }

        public void LoadListNBS()
        {
            //get list Nguon Bo Sung
            var getListDB = libol.ACQ_ACQUIRE_SOURCE.ToList();
            SelectList list = new SelectList(getListDB, "ID", "Source");
            ViewBag.listDemo = list;

        }

        public void LoadListKTL()
        {
            // get list Kieu tu lieu
            var getlistKTL = libol.CIR_LOAN_TYPE.ToList();
            SelectList listKTL = new SelectList(getlistKTL, "ID", "LoanType");
            ViewBag.listKTL = listKTL;
        }
        public void LoadListCurrency()
        {
            // get list Currency
            var selectedValue = 4;
            var getlistKTL = libol.ACQ_CURRENCY.ToList();
            SelectList listKTL = new SelectList(getlistKTL, "", "CurrencyCode", selectedValue);
            ViewBag.listCur = listKTL;
        }

        // demo load Data by Stored Proceduce
        public void Demo()
        {
            string a = "ada";
            var demo = libol.FPT_EDU_ADD_COLLEGE(a);

        }
    }
}