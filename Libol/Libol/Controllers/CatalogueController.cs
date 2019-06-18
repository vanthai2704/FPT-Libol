﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.Models;
using Libol.EntityResult;

namespace Libol.Controllers
{
    public class CatalogueController : Controller
    {
        private LibolEntities db = new LibolEntities();
        CatalogueBusiness catalogueBusiness = new CatalogueBusiness();
        // GET: Catalogue
        public ActionResult MainTab()
        {
            
            return View();
        }

 

        //----------------Add New Cata ----------------
        //---------------------------------------------
        public ActionResult AddNewCatalogue()
        {
            ViewData["ListMarcForm"] = ListMarcForm();
            //Cấp thư mục
            ViewData["listLevelDir"] = db.CAT_DIC_DIRLEVEL.OrderBy(d => d.Description).ToList();
            ViewData["ListRecordType"] = db.CAT_DIC_RECORDTYPE.OrderBy(r => r.Description).ToList();
            ViewData["listItemType"] = db.CAT_DIC_ITEM_TYPE.Where(t => !String.IsNullOrEmpty(t.TypeName)).OrderBy(t => t.TypeName).ToList();
            //vật mang tin
            ViewData["listMedium"] = db.CAT_DIC_MEDIUM.Where(m => !String.IsNullOrEmpty(m.Description)).OrderBy(m => m.Description).ToList();

            byte[] listAccessLevel = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
            ViewData["listAccessLevel"] = listAccessLevel;

            return View();
        }

        [HttpPost]
        public ActionResult AddNewCatalogue(int formId, string dirCode, int mediumId, string recordTypeCode, int itemTypeId, byte accessLevel)
        {
            string cataloguer = this.Session["FullName"].ToString();
            catalogueBusiness.InsertItem(formId, dirCode, mediumId, recordTypeCode, itemTypeId, accessLevel, cataloguer);
            return RedirectToAction("Index", "Shelf");
        }

        [HttpPost]
        public JsonResult LoadFormComplated(int intIsAuthority, int intFormID)
        {
            string fieldCode = GetFieldByID(intIsAuthority,"", intFormID);
            List<GET_CATALOGUE_FIELDS_Result> formComplated = Catalogue(intIsAuthority, intFormID, fieldCode).ToList();
            ViewData["MarcFormComplated"] = formComplated;
            return Json(formComplated, JsonRequestBehavior.AllowGet);
        }

        //get list marc form
        public List<FPT_SP_CATA_GET_MARC_FORM_Result> ListMarcForm()
        {
            List<FPT_SP_CATA_GET_MARC_FORM_Result> list = db.FPT_SP_CATA_GET_MARC_FORM(0, 0).ToList();
            return list;
        }

        
        //get all fields by ID 
        public String GetFieldByID(int intIsAuthority ,string strCreator, int SelectedIndex)
        {
            List<FPT_SP_CATA_GETFIELDS_OF_FORM_Result> GetForm = db.FPT_SP_CATA_GETFIELDS_OF_FORM(SelectedIndex, "", 0).ToList();
            string fields = "";
            foreach(FPT_SP_CATA_GETFIELDS_OF_FORM_Result item in GetForm)
            {
                if(item.FieldCode != "001")
                fields = fields + item.FieldCode + ",";
            }
            return fields;
        }

        //Get Catalogue
        public List<GET_CATALOGUE_FIELDS_Result> Catalogue(int intIsAuthority, int intFormID, string strFieldCodes)
        {
            List<GET_CATALOGUE_FIELDS_Result> list = db.FPT_GET_CATALOGUE_FIELDS(intIsAuthority , intFormID, strFieldCodes, "", 0);
            return list;
        }
        



        //----------------Search Field Cata -----------
        //---------------------------------------------
        public ActionResult SearchCodeNumber()
        {
            return View();
        }

        //----------------Update Cata -----------
        //---------------------------------------------
        public ActionResult UpdateCatalogue()
        {
            return View();
        }
    }
}