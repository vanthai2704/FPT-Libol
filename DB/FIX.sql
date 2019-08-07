GO
/****** Object:  StoredProcedure [dbo].[FPT_GET_PATRON_LOCK_STATISTIC]    Script Date: 07/27/2019 14:34:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[FPT_GET_PATRON_LOCK_STATISTIC]
-- Purpose: Get patron lock statistic
-- Created AnNXT
-- Date 14/07/2019
-- ModifyDate:
	@strPatronCode  varchar(50),
	@strNote nvarchar(200),
	@strLockDateFrom varchar(30),
	@strLockDateTo varchar(30),
	@intCollegeID int
AS
	DECLARE @strSql nvarchar(2000)
	DECLARE @strJoinSQL nvarchar(1000)
	DECLARE @strLikeSql nvarchar(1000)
	
	SET @strSql = 'SELECT CPL.PatronCode, CPL.StartedDate, CPL.Note, ISNULL(CP.FirstName,'''') + '' '' + ISNULL(CP.MiddleName,'''') + '' '' + ISNULL(CP.LastName,'''') as FullName, CPL.StartedDate + CPL.LockedDays as FinishDate, CPL.LockedDays '
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''

	SET @strJoinSQL = @strJoinSQL + ' FROM CIR_PATRON_LOCK CPL, CIR_PATRON CP'
	SET @strLikeSql = @strLikeSql + ' UPPER(CPL.PatronCode)=UPPER(CP.Code) AND'
	
	IF NOT @strPatronCode = ''
		SET @strLikeSql = @strLikeSql + ' UPPER(CPL.PatronCode)=''' + UPPER(@strPatronCode) + ''' AND'
	
	IF NOT @intCollegeID = 0
		BEGIN
			SET @strSql = @strSql + ', CDC.COLLEGE'
			SET @strJoinSQL = @strJoinSQL + ', CIR_PATRON_UNIVERSITY CPU, CIR_DIC_COLLEGE CDC'
			SET @strLikeSql = @strLikeSql + ' CP.ID = CPU.PATRONID AND CPU.COLLEGEID = CDC.ID AND CPU.COLLEGEID = ' + CAST(@intCollegeID AS VARCHAR(20)) + ' AND'
		END
	
	IF NOT @strNote = ''	
		BEGIN
			SET @strLikeSQL = @strLikeSQL + ' CPL.Note LIKE N''%' + @strNote + '%'' AND'
		END
	
	IF NOT @strLockDateFrom = ''
		SET @strLikeSql = @strLikeSql + ' CPL.StartedDate >= ''' + @strLockDateFrom + ''' AND'
		
	IF NOT @strLockDateTo = ''
		SET @strLikeSql = @strLikeSql + ' CPL.StartedDate <= ''' + @strLockDateTo + ''' AND'
	
	SET @strSql = @strSql + @strJoinSQL + ' WHERE ' +@strLikeSQL
	SET @strSql = LEFT(@strSql,LEN(@strSql)-3) + ' ORDER BY CPL.StartedDate DESC'
EXEC (@stRSql)

go	
/******/
ALTER   PROCEDURE [dbo].[FPT_GET_PATRON_RENEW_LOAN_INFOR]
-- Purpose: Get patron renew
-- Created AnhTH
-- Date 05/10/2010
-- ModifyDate:
--- [GET_PATRON_RENEW_LOAN_INFOR] '','','','','','','','',0,1
	@strPatronCode  varchar(50),
	@strItemCode  varchar(30),
	@strCopyNumber  varchar(30),
	@intLibraryID  int,
	@strLocationPrefix varchar(5),
	@intLocationID  varchar(500),
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strCheckInDateFrom varchar(30),
	@strCheckInDateTo varchar(30),
	@intUserID int
AS
	DECLARE @strSql varchar(2000)
	DECLARE @strSql2 varchar(1000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
	DECLARE @strSelectedTabs varchar(500)

BEGIN	
	SET @strSql = 'SELECT DISTINCT REPLACE(REPLACE(REPLACE(REPLACE(F.Content,''$a'',''''),''$b'','' ''),''$c'','' ''),''$n'','' '') as Content,CLH.CopyNumber,CLH.CheckOutDate, CLH.CheckInDate,isnull(CP.FirstName,'''') + '+''' '''+' + isnull(CP.MiddleName,'''') + '+''' ''' +' + isnull(CP.LastName,'''') + '+''' (''' + '+ CP.Code +' + ''')''' + 'as FullName, CR.RenewDate, CR.OverDueDateNew, CR.OverDueDateOld, CLH.OverdueDays, CLH.OverdueFine, H.Price AS Price, H.Currency AS Currency '			
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''


	SET @strJoinSQL = @strJoinSQL + ' FROM CIR_LOAN_HISTORY CLH LEFT JOIN CIR_PATRON CP ON CP.ID = CLH.PatronID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN FIELD200S F ON CLH.ItemID=F.ItemID and F.FieldCode=''245'''
	SET @strJoinSQL = @strJoinSQL + ' RIGHT JOIN CIR_RENEW CR ON CLH.ID = CR.CirLoanHisID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING H ON CLH.CopyNumber = H.CopyNumber '
	
	IF NOT @strItemCode='' 
		BEGIN
			SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN ITEM I ON CLH.ItemID=I.ID'
			SET @strLikeSql = @strLikeSql + 'UPPER(I.Code)='''+UPPER(@strItemCode)+''' AND '
		END

	IF NOT @strCopyNumber=''
		SET @strLikeSql=@strLikeSql + 'CLH.CopyNumber=''' + @strCopyNumber + ''' AND '

	IF NOT @strPatronCode =''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'UPPER(CP.Code)='''+ UPPER(@strPatronCode) +''' AND '
		END
		
	IF NOT @intLibraryID = 0
		BEGIN
			IF NOT @strLocationPrefix ='0'
				BEGIN			
					IF NOT @intLocationID = ''
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ('+ @intLocationID +') AND '
						END
					ELSE
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' AND B.Symbol LIKE '''+ @strLocationPrefix +'%'') AND '
						END
				END
			ELSE
				BEGIN
					SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
				END
		END
	ELSE 
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END	

	IF NOT @strCheckOutDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckOutDate >= '''+@strCheckOutDateFrom+''' AND '	
		END
	IF NOT @strCheckOutDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckOutDate <= '''+@strCheckOutDateTo+''' AND '	
		END
	IF NOT @strCheckInDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckInDate >= ''' + @strCheckInDateFrom +''' AND '	
		END
	IF NOT @strCheckInDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckInDate <= ''' + @strCheckInDateTo + ''' AND '	
		END
	--IF Not @strSerial=''
		--SET @strLikeSQL = @strLikeSQL + 'UPPER(CLH.Serial)='''+ UPPER(@strSerial) +''' AND '
	SET @strSql = @strSql + @strJoinSQL + ' WHERE ' +@strLikeSQL
	SET @strSql = LEFT(@strSql,LEN(@strSql)-3) 
	PRINT '1'
END
	EXEC(@strSql)
PRINT (@strSql)




go
/******/
ALTER   PROCEDURE [dbo].[FPT_GET_PATRON_RENEW_ONLOAN_INFOR]
-- Purpose: Get patron renew
-- Created AnhTH
-- Date 05/10/2010
-- ModifyDate:
--- [GET_PATRON_RENEW_ONLOAN_INFOR] '','','','','','','','',0,1
	@strPatronCode  varchar(50),
	@strItemCode  varchar(30),
	@strCopyNumber  varchar(30),
	@intLibraryID  int,
	@strLocationPrefix varchar(5),
	@intLocationID  varchar(500),
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strCheckInDateFrom varchar(30),
	@strCheckInDateTo varchar(30),
	@intUserID int
AS
	DECLARE @strSql varchar(2000)
	DECLARE @strSql2 varchar(1000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
	DECLARE @strSelectedTabs varchar(500)

BEGIN	
	SET @strSql = 'SELECT DISTINCT REPLACE(REPLACE(REPLACE(REPLACE(F.Content,''$a'',''''),''$b'','' ''),''$c'','' ''),''$n'','' '') as Content,CL.CopyNumber,CL.CheckOutDate, CL.DueDate,isnull(CP.FirstName,'''') + '+''' '''+' + isnull(CP.MiddleName,'''') + '+''' ''' +' + isnull(CP.LastName,'''') + '+''' (''' + '+ CP.Code +' + ''')''' + 'as FullName, CR.RenewDate, CR.OverDueDateNew, CR.OverDueDateOld, H.Price AS Price, H.Currency AS Currency '			
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''


	SET @strJoinSQL = @strJoinSQL + ' FROM CIR_LOAN CL LEFT JOIN CIR_PATRON CP ON CP.ID = CL.PatronID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN FIELD200S F ON CL.ItemID=F.ItemID and F.FieldCode=''245'''
	SET @strJoinSQL = @strJoinSQL + ' RIGHT JOIN CIR_RENEW CR ON CL.ID = CR.CirLoanID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING H ON CL.CopyNumber = H.CopyNumber '
	
	IF NOT @strItemCode='' 
		BEGIN
			SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN ITEM I ON CL.ItemID=I.ID'
			SET @strLikeSql = @strLikeSql + 'UPPER(I.Code)='''+UPPER(@strItemCode)+''' AND '
		END

	IF NOT @strCopyNumber=''
		SET @strLikeSql=@strLikeSql + 'CL.CopyNumber=''' + @strCopyNumber + ''' AND '

	IF NOT @strPatronCode =''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'UPPER(CP.Code)='''+ UPPER(@strPatronCode) +''' AND '
		END

	IF NOT @intLibraryID = 0
		BEGIN
			IF NOT @strLocationPrefix ='0'
				BEGIN			
					IF NOT @intLocationID = ''
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ('+ @intLocationID +') AND '
						END
					ELSE
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' AND B.Symbol LIKE '''+ @strLocationPrefix +'%'') AND '
						END
				END
			ELSE
				BEGIN
					SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
				END
		END
	ELSE
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END

	IF NOT @strCheckOutDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.CheckOutDate >= '''+@strCheckOutDateFrom+''' AND '	
		END
	IF NOT @strCheckOutDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.CheckOutDate <= '''+@strCheckOutDateTo+''' AND '	
		END
	IF NOT @strCheckInDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.CheckInDate >= ''' + @strCheckInDateFrom +''' AND '	
		END
	IF NOT @strCheckInDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.CheckInDate <= ''' + @strCheckInDateTo + ''' AND '	
		END
	--IF Not @strSerial=''
		--SET @strLikeSQL = @strLikeSQL + 'UPPER(CL.Serial)='''+ UPPER(@strSerial) +''' AND '
	SET @strSql = @strSql + @strJoinSQL + ' WHERE ' +@strLikeSQL
	SET @strSql = LEFT(@strSql,LEN(@strSql)-3) 
	PRINT '1'
END
	EXEC(@strSql)
PRINT (@strSql)

go
/******/
ALTER   PROCEDURE [dbo].[FPT_GET_PATRON_LOANINFOR]
-- Purpose: Get patron on loan
-- Created Tuanhv
-- Date 05/09/2004
-- ModifyDate:

	@strPatronCode  varchar(50),
	@strItemCode  varchar(30),
	@strCopyNumber  varchar(30),
	@intLibraryID int,
	@strLocationPrefix varchar(5),
	@intLocationID  varchar(500),
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strCheckInDateFrom varchar(30),
	@strCheckInDateTo varchar(30),
	@strSerial nvarchar(50),
	@intUserID int
AS
	DECLARE @strSql varchar(2000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
	DECLARE @strSelectedTabs varchar(500)
	SET @strSql = 'SELECT DISTINCT REPLACE(REPLACE(REPLACE(REPLACE(F.Content,''$a'',''''),''$b'','' ''),''$c'','' ''),''$n'','' '') as Content,CLH.CopyNumber,CLH.CheckOutDate,CLH.CheckInDate,CLH.RenewCount,CLH.Serial,isnull(CP.FirstName,'''') + '+''' '''+' + isnull(CP.MiddleName,'''') + '+''' ''' +' + isnull(CP.LastName,'''') + '+''' (''' + '+ CP.Code +' + ''')''' + 'as FullName, CLH.OverdueDays,CLH.OverdueFine, H.Price AS Price, H.Currency AS Currency '			
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''


	SET @strJoinSQL = @strJoinSQL + ' FROM CIR_LOAN_HISTORY CLH LEFT JOIN CIR_PATRON CP ON CP.ID = CLH.PatronID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN FIELD200S F ON CLH.ItemID=F.ItemID and F.FieldCode=''245'' '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING H ON CLH.CopyNumber = H.CopyNumber '

	IF NOT @strItemCode='' 
		BEGIN
			SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN ITEM I ON CLH.ItemID=I.ID'
			SET @strLikeSql = @strLikeSql + 'UPPER(I.Code)='''+UPPER(@strItemCode)+''' AND '
		END

	IF NOT @strCopyNumber=''
		SET @strLikeSql=@strLikeSql + 'CLH.CopyNumber=''' + @strCopyNumber + ''' AND '

	IF NOT @strPatronCode =''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'UPPER(CP.Code)='''+ UPPER(@strPatronCode) +''' AND '
		END

	IF NOT @intLibraryID = 0
		BEGIN
			IF NOT @strLocationPrefix ='0'
				BEGIN			
					IF NOT @intLocationID = ''
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ('+ @intLocationID +') AND '
						END
					ELSE
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' AND B.Symbol LIKE '''+ @strLocationPrefix +'%'') AND '
						END
				END
			ELSE
				BEGIN
					SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
				END
		END
	ELSE 
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END
	

	IF NOT @strCheckOutDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckOutDate >= '''+@strCheckOutDateFrom+''' AND '	
		END
	IF NOT @strCheckOutDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckOutDate <= '''+@strCheckOutDateTo+''' AND '	
		END
	IF NOT @strCheckInDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckInDate >= ''' + @strCheckInDateFrom +''' AND '	
		END
	IF NOT @strCheckInDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckInDate <= ''' + @strCheckInDateTo + ''' AND '	
		END
	IF Not @strSerial=''
		SET @strLikeSQL = @strLikeSQL + 'UPPER(CLH.Serial)='''+ UPPER(@strSerial) +''' AND '
	SET @strSql = @strSql + @strJoinSQL + ' WHERE ' +@strLikeSQL
	SET @strSql = LEFT(@strSql,LEN(@strSql)-3) 
EXEC (@stRSql)
print(@stRSql)

go
/******/
ALTER   PROCEDURE [dbo].[FPT_GET_PATRON_ONLOANINFOR]
-- Purpose: Get patron on loan
-- Created Tuanhv
-- Date 31/08/2004
-- ModifyDate:

	@strPatronCode  varchar(50),
	@strItemCode  varchar(30),
	@strCopyNumber  varchar(30),
	@intLibraryID int,
	@strLocationPrefix varchar(5),
	@intLocationID  varchar(500),
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strDueDateFrom varchar(30),
	@strDueDateTo varchar(30),
	@strSerial nvarchar(50),
	@intUserID int
AS
	DECLARE @strSql varchar(2000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
	DECLARE @strSelectedTabs varchar(500)
	SET @strSql = 'SELECT DISTINCT REPLACE(REPLACE(REPLACE(REPLACE(F.Content,''$a'',''''),''$b'','' ''),''$c'','' ''),''$n'','' '') as Content,CL.CopyNumber,CL.CheckOutDate ,CL.DueDate,CL.RenewCount,CL.Serial,isnull(CP.FirstName,'''') + '+''' '''+' + isnull(CP.MiddleName,'''') + '+''' ''' +' + isnull(CP.LastName,'''') + '+'''(''' + '+ CP.Code +' + ''')''' + 'as FullName, H.Price AS Price, H.Currency AS Currency '			
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''


	SET @strJoinSQL = @strJoinSQL + ' FROM CIR_LOAN CL JOIN CIR_PATRON CP ON CP.ID = CL.PatronID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN FIELD200S F ON CL.ItemID=F.ItemID and F.FieldCode=''245'''
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING H ON CL.CopyNumber = H.CopyNumber '

	IF NOT @strItemCode='' 
		BEGIN
			SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN ITEM I ON CL.ItemID=I.ID'
			SET @strLikeSql = @strLikeSql + 'I.Code='''+@strItemCode+''' AND '
		END

	IF NOT @strCopyNumber=''
		SET @strLikeSql=@strLikeSql + 'CL.CopyNumber=''' + @strCopyNumber + ''' AND '

	IF NOT @strPatronCode =''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CP.Code='''+ @strPatronCode +''' AND '
		END

	IF NOT @intLibraryID = 0
		BEGIN
			IF NOT @strLocationPrefix ='0'
				BEGIN			
					IF NOT @intLocationID = ''
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ('+ @intLocationID +') AND '
						END
					ELSE
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' AND B.Symbol LIKE '''+ @strLocationPrefix +'%'') AND '
						END
				END
			ELSE
				BEGIN
					SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
				END
		END
	ELSE
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END	

	IF NOT @strCheckOutDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.CheckOutDate >= '''+@strCheckOutDateFrom+''' AND '	
		END
	IF NOT @strCheckOutDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.CheckOutDate <= '''+@strCheckOutDateTo+''' AND '	
		END
	IF NOT @strDueDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.DueDate >= ''' + @strDueDateFrom +''' AND '	
		END
	IF NOT @strDueDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.DueDate <= ''' + @strDueDateTo + ''' AND '	
		END
	IF NOT @strSerial=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.Serial='''+ @strSerial +''' AND '
		END
	SET @strSql = @strSql + @strJoinSQL + ' WHERE ' +@strLikeSQL
	SET @strSql = LEFT(@strSql,LEN(@strSql)-3) 
	EXEC (@stRSql)
	print(@stRSql)
	
------------------------------------------
GO
/****** Object:  StoredProcedure [dbo].[FPT_COUNT_COPYNUMBER_ONLOAN]    Script Date: 07/29/2019 21:28:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<DUCNV>
-- Create date: <Create Date,,>
-- Description:	So luong dang muon
-- InUsed 
-- =1: dang muon 
-- =============================================
ALTER PROCEDURE [dbo].[FPT_COUNT_COPYNUMBER_ONLOAN] 
@itemID int,
 @intLocationID int,
  @intLibraryID int
	-- Add the parameters for the stored procedure here
	
AS
DECLARE @strSQL NVARCHAR(1000)
SET @strSQL=''

      SET @strSQL=@strSQL +'SELECT COUNT(COPYNUMBER) as SLuong FROM HOLDING WHERE InUsed = 1 AND  ITEMID = ' +convert(nvarchar,@itemID)

	If @intLocationID <>0
		 SET @strSQL=@strSQL + ' AND LocationID='+ convert(nvarchar,@intLocationID)
	If @intLocationID =0
		SET @strSQL=@strSQL + ' AND LibID='+ convert(nvarchar,@intLibraryID)
--print(@strSQL)

      EXEC(@strSQL)
	  
GO
/****** Object:  StoredProcedure [dbo].[SP_CIR_OVERDUELIST_GETINFOR]    */
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[FPT_SP_CIR_OVERDUELIST_GETINFOR]      
--purpose: select overdue items                       
--creator:Nhatnh                      
--createdDate:31/7/2019                      
 @intUserID INT,                      
 @strPatronIDs VARCHAR(1000),                    
  @whereCondition NVARCHAR(1000)                     
AS                      
 DECLARE @strSQL NVARCHAR(4000)                      
 SET @strSQL = ''                  
 SET @strSQL = '(SELECT L.ID AS LOANID, HD.LibID, HD.LocationID AS LocID,HD.Price,HD.Currency , CDC.College, CDF.Faculty, CPU.Grade, CPU.Class, CPU.FacultyID, CPU.CollegeID, P.PatronGroupID, L.LocationID, L.CheckOutDate AS CheckOutDate, L.DueDate AS CheckInDate, F.Content AS MainTitle, L.CopyNumber, P.ID AS PatronID, IsNull(P.FirstName,'''') + ''' + ' ' + ''' + IsNull(P.MiddleName,'''') + ''' + ' ' + ''' + IsNull(P.LastName,'''') AS Name,P.Email,'                 
    --TINH SO NGAY QUA HAN, VA TRU DI NGAY THU 7 VA CHU NHAT                      
 +'OverdueDate=DATEDIFF(DAY,L.DueDate,GETDATE()), '                      
 +'T.OverdueFine*floor(DATEDIFF(DAY,L.DueDate,GETDATE())) AS Penati, P.Code As PatronCode, P.Code,I.code as ItemCode FROM  CIR_LOAN L INNER JOIN CIR_PATRON P ON L.PatronID= P.ID INNER JOIN ITEM I ON L.ItemID=I.ID LEFT JOIN Field200s F ON I.ID=F.ItemID AND F.FieldCode=245 LEFT JOIN CIR_LOAN_TYPE T ON L.LoanTypeID=T.ID LEFT JOIN CIR_PATRON_UNIVERSITY CPU ON CPU.PatronID=P.ID LEFT JOIN CIR_DIC_FACULTY CDF ON CDF.ID=CPU.FacultyID LEFT JOIN CIR_DIC_COLLEGE CDC ON CDC.ID=CPU.CollegeID LEFT JOIN HOLDING HD ON HD.CopyNumber = L.CopyNumber WHERE  L.DueDate<=GETDATE()'                     
                      
 IF @strPatronIDs=''                       
  SET @strSQL= @strSQL + ' AND P.ID IN (SELECT DISTINCT L.PatronID FROM CIR_LOAN L WHERE L.DueDate<GETDATE())) A, '                      
 ELSE                      
  SET @strSQL= @strSQL + ' AND P.ID IN (' + @strPatronIDs + ')) A, '                      
 -- Get Location, Library                       
 SET @strSQL= 'SELECT A.*, B.LibCode, B.LocCode FROM ' + @strSQL + '(SELECT H.Symbol AS LocCode, H.ID, L.Code AS LibCode FROM HOLDING_LOCATION H, HOLDING_LIBRARY L WHERE H.LibID=L.ID AND H.ID IN(SELECT LocationID FROM SYS_USER_CIR_LOCATION WHERE UserID=' 
 + CAST(@intUserID AS NVARCHAR(4)) + ')) B WHERE A.LocationID=B.ID ' + @whereCondition + ' ORDER BY PatronCode '       
 EXEC(@strSQL)	  


 GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_UPDATE_UNLOCK_PATRON_CARD]  Script Date: 7/22/2019 7:22:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[FPT_SP_UPDATE_UNLOCK_PATRON_CARD]
-- Purpose: Update Unlock Locked PatronCard
-- MODIFICATION HISTORY
-- Person      Date    Comments
-- Trinhlv      300804  Create
-- ---------   ------  -------------------------------------------       
	@strPatronCode varchar(500),
	@lockedDay int,
	@Note nvarchar(1000)
AS
	UPDATE [CIR_PATRON_LOCK] SET LockedDays = @lockedDay, Note = @Note WHERE PatronCode = @strPatronCode



GO

/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_REMOVED]    Script Date: 8/6/2019 07:55:08 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- Purpose: Select holidng_remove information
-- @strDateType: 1 - ngày nhận sách, 2 - ngày xóa sách, 3 - ngày gần nhất mà quyển sách được mượn
ALTER PROCEDURE [dbo].[FPT_SP_GET_HOLDING_REMOVED]
	@intLibID	NVARCHAR(100),
	@intLocID	NVARCHAR(100),
	@strShelf	NVARCHAR(10),
	@strCopyNumber	VARCHAR(33),
	@strCallNumber	NVARCHAR(32),
	@strLiquidCode NVARCHAR(100),
	@strVolume	NVARCHAR(32),
	@strTitle	NVARCHAR(1000),
	@strPrice	NVARCHAR(1000),
	@strDateFrom DAtetime,
	@strDateTo DAtetime, 
	@strDateType NVARCHAR(1000),
	@strReason NVARCHAR(100)
AS
	DECLARE @strSQL NVARCHAR(4000)
	DECLARE @strWhere NVARCHAR(4000)
	DECLARE @strTable	NVARCHAR(1000)



	SET @strSQL='SELECT HOLDING_REMOVED.*,LEFT(FIELD200S.Content,50) AS Content,
		HOLDING_REMOVED.REASON as REASON_ID,HOLDING_REMOVE_REASON.REASON as Reson_detail '

	SET @strTable=' FROM (HOLDING_REMOVED Join HOLDING_LOCATION hl on hl.id = HOLDING_REMOVED.LocationID) ,FIELD200S,HOLDING_REMOVE_REASON '

	SET @strWhere=' WHERE Field200s.FieldCode=''245'' AND FIELD200S.ItemID=HOLDING_REMOVED.ItemID 
		AND HOLDING_REMOVE_REASON.ID=HOLDING_REMOVED.Reason'

	IF @strTitle<>'' 
	BEGIN
		SET @strTable=@strTable + ', ITEM_TITLE'	
		SET @strWhere=@strWhere + ' AND HOLDING_REMOVED.ItemID=ITEM_TITLE.ItemID AND ITEM_TITLE.FieldCode=''245'''
	END

	IF @intLibID<>0 
		BEGIN
			SET @strWhere= @strWhere + ' AND HOLDING_LIBRARY.ID=HOLDING_REMOVED.LibID 
			AND HOLDING_REMOVED.LibID=' + RTrim(CAST(@intLibID AS CHAR))

			IF PATINDEX('%,HOLDING_LIBRARY%',@strTable)=0
				SET @strTable= @strTable + ',HOLDING_LIBRARY'
			SET @strSQL=@strSQL + ',Code AS LibName'
		END
	ELSE
		BEGIN
			SET @strSQL=@strSQL + ',Code AS LibName '
			SET @strTable = @strTable + ' , HOLDING_LIBRARY  '
			SET @strWhere = @strWhere + ' AND HOLDING_LIBRARY.ID = HOLDING_REMOVED.LibID '
		END
	IF @intLocID<>0 
		BEGIN
			SET @strWhere= @strWhere + ' AND HOLDING_LOCATION.ID=HOLDING_REMOVED.LocationID 
			AND HOLDING_REMOVED.LocationID=' + RTrim(CAST(@intLocID AS CHAR))
			IF PATINDEX('%, HOLDING_LOCATION%',@strTable)=0
				SET @strTable= @strTable + ',HOLDING_LOCATION '			
		END

	IF @strShelf<>''
		BEGIN
			IF @strShelf='noname'
				SET @strWhere= @strWhere + ' AND (Shelf IS NULL  OR RTrim(LTrim(Shelf)) ='''')'
			ELSE
				SET @strWhere= @strWhere + ' AND Shelf LIKE ''' + @strShelf + ''''
		END
	IF @strCopyNumber<>''
		SET @strWhere= @strWhere + ' AND CopyNumber LIKE ''' + @strCopyNumber + ''''
	IF @strCallNumber<>''
		SET @strWhere= @strWhere + ' AND CallNumber LIKE ''' + @strCallNumber + ''''
	IF @strVolume<>''
		SET @strWhere= @strWhere + ' AND Volume LIKE ''' + @strVolume + ''''
	IF @strTitle<>''
		SET @strWhere= @strWhere + ' AND CONTAINS(Title,''"' + @strTitle +  '"'')'
	IF @strPrice<>''
		SET @strWhere= @strWhere + ' And Price = ' + @strPrice + ' '
	IF @strLiquidCode <>''
		SET @strWhere = @strWhere + ' And LiquidCode = ''' + @strLiquidCode + ''''
	SET @strTable = @strTable + ' '

	SET @strSQL=@strSQL + ', hl.Symbol AS LocName'

	if @strReason<>'-1'
		SET @strWhere = @strWhere + ' and HOLDING_REMOVED.Reason = ' + @strReason + ' ' 

	if @strDateType=1
		begin
			if Convert(nvarchar,@strDateFrom,23) <> ''
				SET @strWhere = @strWhere + ' and HOLDING_REMOVED.AcquiredDate >=''' + Convert(nvarchar,@strDateFrom,23) +'''' 
			if Convert(nvarchar,@strDateTo,23) <> ''
				SET @strWhere = @strWhere + ' and HOLDING_REMOVED.AcquiredDate <=''' + Convert(nvarchar,DATEADD(DAY,1,@strDateTo),23) +''''
		end
	else if @strDateType=2
		begin 
			if Convert(nvarchar,@strDateFrom,23) <> ''
				SET @strWhere = @strWhere + ' and HOLDING_REMOVED.RemovedDate >=''' + Convert(nvarchar,@strDateFrom,23) +'''' 
			if Convert(nvarchar,@strDateTo,23) <> ''
				SET @strWhere = @strWhere + ' and HOLDING_REMOVED.RemovedDate <''' + Convert(nvarchar,DATEADD(DAY,1,@strDateTo),23) +''''
		end
	else if @strDateType = 3
		begin 
			if Convert(nvarchar,@strDateFrom,23) <> ''
				SET @strWhere = @strWhere + ' and HOLDING_REMOVED.DateLastUsed >=''' + Convert(nvarchar,@strDateFrom,23) +'''' 
			if Convert(nvarchar,@strDateTo,23) <> ''
				SET @strWhere = @strWhere + ' and HOLDING_REMOVED.DateLastUsed <''' + Convert(nvarchar,DATEADD(DAY,1,@strDateTo),23) +''''
		end

PRINT @strSQL + @strTable + @strWhere
	EXECUTE(@strSQL + @strTable + @strWhere)
GO

GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_ITEM]    Script Date: 07/28/2019 17:32:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<ducnv>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ DANH MỤC SÁCH NHẬP
-- =============================================
ALTER  PROCEDURE [dbo].[FPT_SP_GET_ITEM]

      @strFromDate VARCHAR(30),

      @strToDate  VARCHAR(30),

      @intLocationID    int,
      
      @intLibraryID int

AS   

      DECLARE @strSQL NVARCHAR(1000)
	  DECLARE @strLike NVARCHAR(1000)
	  DECLARE @strJoin NVARCHAR(1000)
      SET @strSQL=''
      SET @strJoin=''
	  SET @strLike = ''
      SET @strSQL=@strSQL + 'SELECT I.ID,I.Code, U.DKCB, F.Content 
      FROM ITEM I
      join FIELD200S F on I.ID=F.ITEMID
join (SELECT distinct ItemID ,
STUFF(( SELECT  '', '' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID'
SET @strJoin = @strJoin+ 'FOR XML PATH('''')), 1, 1, '''') AS DKCB FROM HOLDING D2 GROUP BY ItemID) as U on I.ID = U.ItemID
WHERE FIELDCODE=''245'' AND (I.TYPEID=1 OR I.TypeID=15)'

      If @strFromDate<>''

            SET @strJoin=@strJoin + ' AND I.CreatedDate>=CONVERT(VARCHAR, '''+@strFromDate+''', 21)'

      If @strToDate<>''

            SET @strJoin=@strJoin + ' AND I.CreatedDate<=CONVERT(VARCHAR, '''+@strToDate+''', 21)'

      If @intLocationID <>0
		BEGIN
            SET @strJoin=@strJoin + ' AND I.ID IN (SELECT ITEMID FROM HOLDING WHERE LocationID='+ convert(nvarchar,@intLocationID) +')'
            SET @strLike = @strLike + ' AND D1.LocationID=' +convert(nvarchar,@intLocationID)
        END    
       If @intLocationID =0
		BEGIN
            SET @strJoin=@strJoin + ' AND I.ID IN (SELECT ITEMID FROM HOLDING WHERE LibID='+ convert(nvarchar,@intLibraryID) +')'
			SET @strLike = @strLike + ' AND D1.LibID=' +convert(nvarchar,@intLibraryID)
		END
		SET @strSQL = @strSQL+ @strLike + @strJoin
    --print(@strSQL)

      EXEC(@strSQL)
      

