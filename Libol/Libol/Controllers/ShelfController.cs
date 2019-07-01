﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.EntityResult;
using Libol.Models;

namespace Libol.Controllers
{
    public class ShelfController : Controller
    {
        LibolEntities libol = new LibolEntities();
        ShelfBusiness shelfBusiness = new ShelfBusiness();
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

            List< SP_HOLDING_LIBRARY_SELECT_Result > listLibsResult = shelfBusiness.FPT_SP_HOLDING_LIBRARY_SELECT(0, 1, -1, 49, 1);
            List<HOLDING_LIBRARY> libs = SP_HOLDING_LIBRARY_SELECT_Result.ConvertToHoldingLibrary(listLibsResult);
            List<SP_HOLDING_LOCATION_GET_INFO_Result> listLocsResult = shelfBusiness.FPT_SP_HOLDING_LOCATION_GET_INFO(20, 49, 0, -1);
            List<HOLDING_LOCATION> locs = SP_HOLDING_LOCATION_GET_INFO_Result.ConvertToHoldingLocation(listLocsResult);

            ViewData["listLibs"] = libs;
            ViewData["listLocs"] = locs;

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

        [HttpPost]
        public JsonResult GenCopyNumber(int locId)
        {
            string copyNumber = shelfBusiness.GenCopyNumber(locId);
            return Json(new Result()
            {
               
                Data = copyNumber
            }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public JsonResult InsertHolding(HOLDING holding,int numberOfCN)
        {
           List<HOLDING> listHoldings = shelfBusiness.InsertHolding(holding,numberOfCN);
            return Json(listHoldings);
        }

    }
}