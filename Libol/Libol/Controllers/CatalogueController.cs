using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.Models;
using Libol.EntityResult;

namespace Libol.Controllers
{
    public class CatalogueController : BaseController
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
            //get list marc form
            ViewData["ListMarcForm"] = db.FPT_SP_CATA_GET_MARC_FORM(0, 0).ToList();
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
        public JsonResult LoadFormComplated(int intIsAuthority, int intFormID)
        {
            //catalogueBusiness.CheckExistNumber("9781184", "020$a");
            //string fieldCode = GetFieldByID(intIsAuthority,"", intFormID);
            List<GET_CATALOGUE_FIELDS_Result> formComplated = catalogueBusiness.GetComplatedForm(0, "", intFormID);
            ViewData["MarcFormComplated"] = formComplated;
            
            return Json(formComplated, JsonRequestBehavior.AllowGet);
        }

        //----------------Add Item For Detail -----------
        //---------------------------------------------

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
        
        public ActionResult AddNewCatalogueDetail(string fieldCode , string fieldValue)
=======
       
        public ActionResult AddNewCatalogueDetail()
>>>>>>> parent of 71010c2... Merge branch 'DoanhDQ'
=======
       
<<<<<<< HEAD
        public ActionResult AddNewCatalogueDetail()
>>>>>>> parent of 71010c2... Merge branch 'DoanhDQ'
        {
            //get list marc form
            ViewData["ListMarcForm"] = db.FPT_SP_CATA_GET_MARC_FORM(0, 0).ToList();
            //Cấp thư mục
            ViewData["listLevelDir"] = db.CAT_DIC_DIRLEVEL.OrderBy(d => d.Description).ToList();
            ViewData["ListRecordType"] = db.CAT_DIC_RECORDTYPE.OrderBy(r => r.Description).ToList();
            ViewData["listItemType"] = db.CAT_DIC_ITEM_TYPE.Where(t => !String.IsNullOrEmpty(t.TypeName)).OrderBy(t => t.TypeName).ToList();
            //vật mang tin
            ViewData["listMedium"] = db.CAT_DIC_MEDIUM.Where(m => !String.IsNullOrEmpty(m.Description)).OrderBy(m => m.Description).ToList();
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> parent of 280c507... Doanhdq
=======
>>>>>>> parent of 71010c2... Merge branch 'DoanhDQ'
=======
>>>>>>> parent of 71010c2... Merge branch 'DoanhDQ'

            byte[] listAccessLevel = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
            ViewData["listAccessLevel"] = listAccessLevel;
            return View();
        }

        [HttpPost]
        public ActionResult InsertOrUpdateCatalogue(List<string> listFieldsName, List<string> listFieldsValue, ITEM item)
=======
        public ActionResult AddNewCatalogueDetail(List<string> listFieldsName, List<string> listFieldsValue, ITEM item)
>>>>>>> parent of a3cf7ba... Merge branch 'master' into ThaiNV
        {
            catalogueBusiness.InsertOrUpdateFields(listFieldsName, listFieldsValue, item);
            return View();
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

        //
        
    }
}