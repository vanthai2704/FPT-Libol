using System;
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
            return View();
        }
        [HttpPost]
        public JsonResult LoadFormComplated(int intIsAuthority, int intFormID)
        {
            string fieldCode = GetFieldByID(intIsAuthority,"", intFormID);
            List<GET_CATALOGUE_FIELDS_Result> formComplated = Catalogue(intIsAuthority, intFormID, fieldCode);
            ViewData["MarcFormComplated"] = formComplated;
            return Json("", JsonRequestBehavior.AllowGet);
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