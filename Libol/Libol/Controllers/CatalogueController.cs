using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.Models;

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

        public List<FPT_SP_CATA_GET_MARC_FORM_Result> ListMarcForm()
        {
            List<FPT_SP_CATA_GET_MARC_FORM_Result> list = db.FPT_SP_CATA_GET_MARC_FORM(0, 0).ToList();
            return list;

        }

        public String GetFieldByID(int SelectedIndex)
        {
            List<FPT_SP_CATA_GETFIELDS_OF_FORM_Result> GetForm = db.FPT_SP_CATA_GETFIELDS_OF_FORM(SelectedIndex , "" , null).ToList();

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