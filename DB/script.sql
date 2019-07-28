﻿go
CREATE FUNCTION [dbo].[ufn_removeMark] (@text nvarchar(max))
RETURNS nvarchar(max)
AS
BEGIN
	SET @text = LOWER(@text)
	DECLARE @textLen int = LEN(@text)
	IF @textLen > 0
	BEGIN
		DECLARE @index int = 1
		DECLARE @lPos int
		DECLARE @SIGN_CHARS nvarchar(100) = N'ăâđêôơưàảãạáằẳẵặắầẩẫậấèẻẽẹéềểễệếìỉĩịíòỏõọóồổỗộốờởỡợớùủũụúừửữựứỳỷỹỵýđð'
		DECLARE @UNSIGN_CHARS varchar(100) = 'aadeoouaaaaaaaaaaaaaaaeeeeeeeeeeiiiiiooooooooooooooouuuuuuuuuuyyyyydd'

		WHILE @index <= @textLen
		BEGIN
			SET @lPos = CHARINDEX(SUBSTRING(@text,@index,1),@SIGN_CHARS)
			IF @lPos > 0
			BEGIN
				SET @text = STUFF(@text,@index,1,SUBSTRING(@UNSIGN_CHARS,@lPos,1))
			END
			SET @index = @index + 1
		END
	END
	RETURN @text
END

go
/******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO
CREATE TABLE SYS_USER_GOOGLE_ACCOUNT(
	Email varchar(500) NOT NULL PRIMARY KEY,
	ID INT NOT NULL
)

GO

/******/
create PROCEDURE [dbo].[FPT_SP_CATA_GET_MARC_FORM]
-- ---------   ------  -------------------------------------------
	@intFormID	int,
	@intIsAuthority	int
AS
	DECLARE @strSelectStatement	nvarchar(150)

	IF @intIsAuthority = 0
		BEGIN
			SELECT * FROM MARC_WORKSHEET
			IF NOT @intFormID = 0
				SELECT * FROM MARC_WORKSHEET WHERE ID = + CAST(@intFormID AS CHAR(4))
		END
	ELSE
		BEGIN
			SELECT * FROM MARC_AUTHORITY_WORKSHEET
			IF NOT @intFormID = 0
				SELECT * FROM MARC_AUTHORITY_WORKSHEET WHERE ID =  CAST(@intFormID AS CHAR(4))
		END
		Go

/******/
create  PROCEDURE [dbo].[FPT_SP_CATA_GETFIELDS_OF_FORM]
-- ---------   ------  -------------------------------------------
	@intFormID	int,
	@strCreator	nvarchar(50),
	@intIsAuthority	int
AS
	DECLARE @strSelectStatement	nvarchar(300)
	IF @intIsAuthority = 0
		BEGIN		
			IF NOT @intFormID = 0	
				SELECT * FROM MARC_WORKSHEET A LEFT JOIN MARC_BIB_WS_DETAIL B ON A.ID = B.FormID WHERE A.ID =  + CAST(@intFormID AS CHAR(4))
		END
	ELSE 
	-- Authority data
		BEGIN
			SET @strSelectStatement = ''
			IF NOT @intFormID = 0	
				SELECT * FROM MARC_AUTHORITY_WORKSHEET A LEFT JOIN MARC_AUTHORITY_WS_DETAIL B ON A.ID = B.FormID WHERE A.ID = + CAST(@intFormID AS CHAR(4))
		END
	
	Go

/******/
create PROCEDURE [dbo].[FPT_SP_CATA_CHECK_EXIST_TITLE]
-- ---------   ------  -------------------------------------------
	@strTitle	nvarchar(200),
	@strItemType	varchar(5)
   -- Declare program variables as shown above
AS
	DECLARE @strSelectStatement	nvarchar(500)
	IF NOT @strItemType = ''
	-- Forming SelectStatement
		SELECT ItemID, Content FROM FIELD200S WHERE FieldCode = '245' AND Content LIKE N'$a' + @strTitle + '%' AND ItemID IN (SELECT TOP 50 A.TypeID FROM ITEM A, CAT_DIC_ITEM_TYPE B WHERE A.TypeID = B.ID AND UPPER(B.TypeCode) = UPPER('' + RTRIM(@strItemType) + ''))
	ELSE
		SELECT ItemID, Content FROM FIELD200S WHERE FieldCode = '245' AND Content LIKE N'$a' + @strTitle + '%'
	-- Execute

	go
/******/
	CREATE PROC [dbo].[FPT_SP_ILL_SEARCH_PATRON] 
-- Purpose: Search Patron update search khong dau
@strPatronName NVARCHAR(50),  
@strPatronCode VARCHAR(50)  
AS  
DECLARE @strSQL NVARCHAR(500)  
	SET @strSQL='select*,dbo.ufn_removeMark(FullName) as FullNameSimple from(select Code,ValidDate,ExpiredDate,DOB,(IsNull(FirstName,'''') + '' '' + IsNull(MiddleName +'' '' ,'''')  + IsNull(LastName,'''')) AS FullName from CIR_PATRON '
	
	IF @strPatronCode <>'' 
		SET @strSQL=@strSQL + ' AND Code LIKE ''' + @strPatronCode + ''''  
	
	SET @strSQL=@strSQL + ') A'
	IF @strPatronName<>'' 
		SET @strSQL=@strSQL + ' WHERE A.FullName  LIKE N''%' + @strPatronName + '%'' or dbo.ufn_removeMark(FullName) like dbo.ufn_removeMark(N''%' + @strPatronName + '%'')'

EXECUTE(@strSQL)

go
/******/
CREATE      PROCEDURE [dbo].[FPT_SP_CIR_GET_RENEW]
	@intUserID	INT,
	@intType	SMALLINT,
	@strCodeVal	VARCHAR(50)
AS
	DECLARE	@strSQLSel  NVARCHAR(2000)
	DECLARE	@strSQLTab  NVARCHAR(100)
	DECLARE	@strSQLJoin  NVARCHAR(1000)

	SET @strSQLSel='SELECT Content, Renewals, RenewalPeriod, TimeUnit, FirstName + '' '' + MiddleName + '' '' + LastName AS FullName
	, CIR_PATRON.Code, CIR_LOAN.*, '' '' AS strNote, '' '' AS TimeHold ,getdate() as Today' 
	SET @strSQLTab='CIR_PATRON, CIR_LOAN_TYPE, CIR_LOAN, HOLDING,FIELD200S'
	SET @strSQLJoin=' CIR_PATRON.ID=CIR_LOAN.PatronID AND CIR_LOAN.LoanTypeID=CIR_LOAN_TYPE.ID AND HOLDING.CopyNumber=CIR_LOAN.CopyNumber AND CIR_LOAN.DueDate IS NOT NULL
	AND HOLDING.ItemID=CIR_LOAN.ItemID AND HOLDING.LocationID IN(SELECT LocationID FROM SYS_USER_CIR_LOCATION WHERE UserID = ' + RTrim(CAST(@intUserID AS CHAR)) + ') 
	AND FIELD200S.ItemID=CIR_LOAN.ItemID AND FIELD200S.FieldCode=''245'''
	IF @intType=1
		SET @strSQLJoin=@strSQLJoin + ' AND CIR_PATRON.Code=''' + @strCodeVal + ''''
	IF @intType=2
		BEGIN
			SET @strSQLTab=@strSQLTab + ',ITEM'
			SET @strSQLJoin=@strSQLJoin + ' AND ITEM.ID=CIR_LOAN.ItemID AND ITEM.Code=''' + @strCodeVal + ''''
		END
	IF @intType=3
		SET @strSQLJoin=@strSQLJoin + ' AND CIR_LOAN.CopyNumber=''' + @strCodeVal + ''''

	EXEC(@strSQLSel + ' FROM ' + @strSQLTab + ' WHERE ' +  @strSQLJoin)

go
/******/
CREATE PROCEDURE [dbo].[FPT_ADMIN_GET_RIGHTS_ACCEPT]
	@intModuleID int,
	@intUserID int
AS
SELECT R.ID, R.[Right] FROM SYS_USER_RIGHT_DETAIL D JOIN SYS_USER_RIGHT R ON D.RightID = R.ID
WHERE D.UserID = @intUserID AND R.ModuleID = @intModuleID

go
/******/
CREATE PROCEDURE [dbo].[FPT_ADMIN_GET_RIGHTS_DENY]
	@intModuleID int,
	@intUserID int,
	@intUserParentID int
AS

SELECT R.ID, R.[Right] FROM SYS_USER_RIGHT R 
JOIN SYS_USER_RIGHT_DETAIL D ON R.ID = D.RightID 
WHERE R.ModuleID = @intModuleID AND D.UserID = @intUserParentID AND R.ID 
NOT IN (
	SELECT U.ID FROM SYS_USER_RIGHT_DETAIL D JOIN SYS_USER_RIGHT U ON D.RightID = U.ID
	WHERE D.UserID = @intUserID AND U.ModuleID = @intModuleID
)

go
/******/
CREATE PROCEDURE [dbo].[FPT_ADMIN_GET_RIGHTS_WHEN_CREATE]
	@intModuleID int,
	@intParentID int,
	@IsBasic int
AS

SELECT R.ID, R.[Right] FROM SYS_USER_RIGHT R 
JOIN SYS_USER_RIGHT_DETAIL D ON R.ID = D.RightID 
JOIN SYS_USER E ON D.UserID = E.ID 
WHERE D.UserID = @intParentID AND R.ModuleID = @intModuleID AND R.IsBasic = @IsBasic


go
/******/
Create PROCEDURE [dbo].[FPT_ACQ_MONTH_STATISTIC] 
	@intLibraryID int,
	@intLocationID int,
	@strInYear varchar(4),
	@intUserID int
AS
	DECLARE @strSQL varchar(1000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
		
	SET @strSQL = 'SELECT MONTH(AcquiredDate) AS Month, Count(DISTINCT ItemID) AS BooksTotal, COUNT(*) AS CopiesTotal, 
    MoneyTotal = SUM(ISNULL(Price,0)) '
	SET @strJoinSQL = 'FROM HOLDING '
	SET @strLikeSql = '1 =1 AND '
	
	IF NOT @intLibraryID = 0
		BEGIN		
			IF NOT @intLocationID = 0
				SET @strLikeSQL = @strLikeSQL + 'LocationID = ' + CAST(@intLocationID AS VARCHAR(10)) +' AND '
			ELSE
				SET @strLikeSQL = @strLikeSQL + 'LibID = ' + CAST(@intLibraryID AS VARCHAR(10)) + ' AND '		
		END
	ELSE 
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'LocationID IN ( SELECT B.ID AS ID FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END
	
	IF NOT @strInYear = ''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'DATEPART(year, AcquiredDate) = '+@strInYear+' AND '	
		END
		
	SET @strSQL = @strSQL + @strJoinSQL + ' WHERE ' +@strLikeSQL 
	SET @strSQL = LEFT(@strSQL,LEN(@strSQL)-3) 
	SET @strSQL = @strSQL + ' GROUP BY Month(AcquiredDate) ORDER BY MONTH ASC'
	--process here
EXEC(@strSQL)


go
/******/
Create PROCEDURE [dbo].[FPT_ACQ_YEAR_STATISTIC] 
	@intLibraryID int,
	@intLocationID int,
	@strFromYear varchar(4),
	@strToYear varchar(4),
	@intUserID int
AS
	DECLARE @strSQL varchar(1000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
		
	SET @strSQL = 'SELECT YEAR(AcquiredDate) AS YEAR, Count(DISTINCT ItemID) AS BooksTotal, COUNT(*) AS CopiesTotal, 
    MoneyTotal = SUM(ISNULL(Price,0)) '
	SET @strJoinSQL = 'FROM HOLDING '
	SET @strLikeSql = '1 =1 AND '
	
	IF NOT @intLibraryID = 0
		BEGIN		
			IF NOT @intLocationID = 0
				SET @strLikeSQL = @strLikeSQL + 'LocationID = ' + CAST(@intLocationID AS VARCHAR(10)) +' AND '
			ELSE
				SET @strLikeSQL = @strLikeSQL + 'LibID = ' + CAST(@intLibraryID AS VARCHAR(10)) + ' AND '		
		END
	ELSE 
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'LocationID IN ( SELECT B.ID AS ID FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END
	
	IF NOT @strFromYear = ''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'DATEPART(year, AcquiredDate) >= '+@strFromYear+' AND '	
		END
		
	IF NOT @strToYear = ''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'DATEPART(year, AcquiredDate) <= '+@strToYear+' AND '	
		END
		
	SET @strSQL = @strSQL + @strJoinSQL + ' WHERE ' +@strLikeSQL 
	SET @strSQL = LEFT(@strSQL,LEN(@strSQL)-3) 
	SET @strSQL = @strSQL + ' GROUP BY YEAR(AcquiredDate) ORDER BY YEAR ASC'
	--process here
EXEC(@strSQL)

go
/******/
Create PROCEDURE [dbo].[FPT_BORROWNUMBER] (@itemID int, @price real, @acqdate varchar(50))
	-- Add the parameters for the stored procedure here
	
AS
DECLARE @sql varchar(1000)
SET @sql = ''+CONVERT (varchar(10), @acqdate, 21)
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SELECT COUNT(COPYNUMBER) FROM HOLDING WHERE ITEMID = @itemID AND PRICE = @price AND AcquiredDate = @sql
END


go
/******/
Create PROCEDURE [dbo].[FPT_CHECK_ITEMID_AND_ACQUIREDATE](@LocID int, @CDate date, @itemId int)
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	select ItemID  from Holding 
where AcquiredDate < CONVERT (varchar(10), @CDate, 21) and ItemID = @itemId and LocationID = @LocID
END

go
/******/
Create PROCEDURE [dbo].[FPT_CIR_GET_LOCFULLNAME_LIBUSER_SEL](@intUserID int,@intLibID int, @strLocPrefix nvarchar(3))
AS
	SELECT CODE + ':' + SYMBOL AS LOCNAME, B.ID AS ID, REPLACE(CAST(A.ID AS CHAR(3)) + ':' + CAST(B.ID AS CHAR(3)), ' ', '') AS GroupID, A.ID AS LibID, B.Symbol, A.Code
	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C 
	WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID = @intUserID AND B.LibID = @intLibID AND B.SYMBOL LIKE ''+@strLocPrefix+'%'
	ORDER BY B.LibID, B.Symbol


	go
/******/
Create PROCEDURE [dbo].[FPT_CIR_GET_LOCLIBUSER_PREFIX_SEL](@intUserID int,@intLibID int)
AS
	SELECT distinct(cast(B.Symbol as nvarchar(3))) as LocationCode
	FROM [Libol].[dbo].[HOLDING_LOCATION] B, HOLDING_LIBRARY A, SYS_USER_CIR_LOCATION C 
	WHERE LibID = @intLibID AND B.LIBID = A.ID AND C.LOCATIONID = B.ID AND C.USERID = @intUserID


	go
/******/
Create PROCEDURE [dbo].[FPT_CIR_MONTH_STATISTIC] 
@intLibraryID int,
@intLocationID int,
@intType int,
@intStatus int,
@strInYear varchar(4),
@intUserID int
AS
	DECLARE @strSQL varchar(1000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)	
	
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''
	
	IF @intType = 1 -- Stat by ItemID
		SET @strSQL = 'SELECT TotalLoan = Count (distinct ITEMID)'
	
	IF @intType = 2 -- Stat by ID (CopyNumber)
		SET @strSQL = 'SELECT TotalLoan = Count (ID)'
		
	IF @intType = 3 -- Stat by PatronID
		SET @strSQL = 'SELECT TotalLoan = Count (distinct PATRONID)'
			
	SET @strSQL = @strSQL + ', MONTH = DATEPART(month, CheckOutDate) '	
		
	IF @intStatus = 0 -- Used
		SET @strJoinSQL = ' FROM CIR_LOAN_HISTORY'
	ELSE -- Using
		SET @strJoinSQL = ' FROM CIR_LOAN'
		
	IF NOT @intLibraryID = 0
		BEGIN		
			IF NOT @intLocationID = 0
				SET @strLikeSQL = @strLikeSQL + 'LocationID = '+ CAST(@intLocationID AS VARCHAR(10)) +' AND '
			ELSE
				SET @strLikeSQL = @strLikeSQL + 'LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ') AND '		
		END
	ELSE 
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END
	
	IF NOT @strInYear = ''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'DATEPART(year, CheckOutDate) = '+@strInYear+' AND '	
		END
		
		
	SET @strSQL = @strSQL + @strJoinSQL + ' WHERE ' +@strLikeSQL 
	SET @strSQL = LEFT(@strSQL,LEN(@strSQL)-3) 
	SET @strSQL = @strSQL + ' GROUP BY DATEPART(Month, CheckOutDate) ORDER BY MONTH ASC'
	--process here
EXEC(@strSQL)


go
/******/
Create PROCEDURE [dbo].[FPT_CIR_YEAR_STATISTIC] 
@intLibraryID int,
@intLocationID int,
@intType int,
@intStatus int,
@strFromYear varchar(4),
@strToYear varchar(4),
@intUserID int
AS
	DECLARE @strSQL varchar(1000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
	
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''	

	IF @intType = 1 -- Stat by ItemID
		SET @strSQL = 'SELECT TotalLoan = Count (distinct ITEMID)'
	
	IF @intType = 2 -- Stat by ID (CopyNumber)
		SET @strSQL = 'SELECT TotalLoan = Count (ID)'
		
	IF @intType = 3 -- Stat by PatronID
		SET @strSQL = 'SELECT TotalLoan = Count (distinct PATRONID)'
		
	SET @strSQL = @strSQL + ', Year = DATEPART(year, CheckOutDate) '	
			
	IF @intStatus = 0 -- Used
		SET @strJoinSQL = ' FROM CIR_LOAN_HISTORY'
	ELSE -- Using
		SET @strJoinSQL = ' FROM CIR_LOAN'
		
	IF NOT @intLibraryID = 0
		BEGIN		
			IF NOT @intLocationID = 0
				SET @strLikeSQL = @strLikeSQL + 'LocationID = '+ CAST(@intLocationID AS VARCHAR(10)) +' AND '
			ELSE
				SET @strLikeSQL = @strLikeSQL + 'LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ') AND '		
		END
	ELSE 
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END
	
	IF NOT @strFromYear = ''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'DATEPART(year, CheckOutDate) >= '+@strFromYear+' AND '	
		END
		
	IF NOT @strToYear = ''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'DATEPART(year, CheckOutDate) <= '+@strToYear+' AND '	
		END
		
	SET @strSQL = @strSQL + @strJoinSQL + ' WHERE ' +@strLikeSQL 
	SET @strSQL = LEFT(@strSQL,LEN(@strSQL)-3) 
	SET @strSQL = @strSQL + ' GROUP BY DATEPART(Year, CheckOutDate) ORDER BY Year ASC'
	--process here
EXEC(@strSQL)


go
/******/
Create PROCEDURE [dbo].[FPT_GET_LIQUIDBOOKS]
	@strLiquidCode VARCHAR(500),
	@intLibraryID int,
	@intLocationID int,
	@strDateFrom varchar(30),
	@strDateTo varchar(30),
	@intUserID int
AS

	DECLARE @strSQL VARCHAR(8000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
	SET @strSQL = 'SELECT HRR.Reason,
	REPLACE(REPLACE(REPLACE(REPLACE(F.Content,''$a'',''''),''$b'','' ''),''$c'','' ''),''$n'','' '') as Content,
	HR.AcquiredSourceID,HR.CallNumber,HR.CopyNumber,
	HR.ID,HR.ItemID,HR.LibID,HR.LiquidCode,
	HR.LoanTypeID,HR.LocationID,HR.PoID,HR.Price,HR.Shelf,HR.UseCount,HR.Volume,
	HR.AcquiredDate,HR.RemovedDate,HR.DateLastUsed,
	Code AS LibName, Symbol AS LocName '
	
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''
	
	SET @strJoinSQL = @strJoinSQL + ' FROM HOLDING_REMOVED HR LEFT JOIN FIELD200S F ON HR.ItemID = F.ItemID AND F.FieldCode=''245'' '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING_REMOVE_REASON HRR ON HR.Reason=HRR.ID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING_LIBRARY HL ON HR.LibID = HL.ID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING_LOCATION HLC ON HR.LocationID = HLC.ID '
		
	IF NOT @strLiquidCode=''
		BEGIN
			SET @strLikeSql=@strLikeSql+' LiquidCode='''+@strLiquidCode+''' AND '
		END
	IF NOT @intLibraryID = 0
		BEGIN
			SET @strLikeSql = @strLikeSql + 'HR.LibID = ' + CAST(@intLibraryID AS VARCHAR(10)) +' AND '
			IF NOT @intLocationID = 0
				BEGIN
					SET @strLikeSql = @strLikeSql + 'HR.LocationID = ' + CAST(@intLocationID AS VARCHAR(10)) +' AND '
				END
			ELSE 
				BEGIN
					SET @strLikeSql = @strLikeSql + 'HR.LocationID IN (SELECT B.ID AS ID FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
				END
		END
	IF NOT @strDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'HR.RemovedDate >= ''' + @strDateFrom +''' AND '	
		END
	IF NOT @strDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'HR.RemovedDate <= ''' + @strDateTo +''' AND '	
		END
	
	
	SET @strSql = @strSql + @strJoinSQL + ' WHERE ' +@strLikeSQL
	SET @strSql = LEFT(@strSql,LEN(@strSql)-3) 
EXEC(@strSQL)
PRINT(@strSQL)


go
/******/
Create PROCEDURE [dbo].[FPT_GET_LOCFULLNAME_LIBUSER_SEL](@intUserID int,@intLibID int, @strLocPrefix nvarchar(3))
AS
	SELECT CODE + ':' + SYMBOL AS LOCNAME, B.ID AS ID, REPLACE(CAST(A.ID AS CHAR(3)) + ':' + CAST(B.ID AS CHAR(3)), ' ', '') AS GroupID, A.ID AS LibID, B.Symbol, A.Code
	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_LOCATION C 
	WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocID AND C.UserID = @intUserID AND B.LibID = @intLibID AND B.SYMBOL LIKE ''+@strLocPrefix+'%'
	ORDER BY B.LibID, B.Symbol


go
/******/
Create   PROCEDURE [dbo].[FPT_GET_PATRON_LOANINFOR]
-- Purpose: Get patron on loan
-- Created Tuanhv
-- Date 05/09/2004
-- ModifyDate:

	@strPatronCode  varchar(50),
	@strItemCode  varchar(30),
	@strCopyNumber  varchar(30),
	@intLibraryID int,
	@strLocationPrefix varchar(5),
	@intLocationID  int,
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strCheckInDateFrom varchar(30),
	@strCheckInDateTo varchar(30),
	@strSerial nvarchar(50),
	@intUserID int
AS
	DECLARE @strSql varchar(1000)
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
					IF NOT @intLocationID = 0
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID='+ CAST(@intLocationID AS VARCHAR(10)) +' AND '
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
Create   PROCEDURE [dbo].[FPT_GET_PATRON_ONLOANINFOR]
-- Purpose: Get patron on loan
-- Created Tuanhv
-- Date 31/08/2004
-- ModifyDate:

	@strPatronCode  varchar(50),
	@strItemCode  varchar(30),
	@strCopyNumber  varchar(30),
	@intLibraryID int,
	@strLocationPrefix varchar(5),
	@intLocationID  int,
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strDueDateFrom varchar(30),
	@strDueDateTo varchar(30),
	@strSerial nvarchar(50),
	@intUserID int
AS
	DECLARE @strSql varchar(1000)
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
					IF NOT @intLocationID = 0
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CL.LocationID='+ CAST(@intLocationID AS VARCHAR(10)) +' AND '
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

	
go	
/******/
Create   PROCEDURE [dbo].[FPT_GET_PATRON_RENEW_LOAN_INFOR]
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
	@intLocationID  int,
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strCheckInDateFrom varchar(30),
	@strCheckInDateTo varchar(30),
	@intUserID int
AS
	DECLARE @strSql varchar(1000)
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
					IF NOT @intLocationID = 0
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID='+ CAST(@intLocationID AS VARCHAR(10)) +' AND '
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
Create   PROCEDURE [dbo].[FPT_GET_PATRON_RENEW_ONLOAN_INFOR]
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
	@intLocationID  int,
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strCheckInDateFrom varchar(30),
	@strCheckInDateTo varchar(30),
	@intUserID int
AS
	DECLARE @strSql varchar(1000)
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
					IF NOT @intLocationID = 0
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CL.LocationID='+ CAST(@intLocationID AS VARCHAR(10)) +' AND '
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
Create PROCEDURE [dbo].[FPT_JOIN_ISBN] (@itemid int)
	-- Add the parameters for the stored procedure here
AS
BEGIN
	SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
WHERE ITEMID = @itemid
GROUP BY ItemID

END


go
/******/
Create PROCEDURE [dbo].[FPT_SELECT_USECOUNT2] (@LibID int, @itemID int, @cDate date)
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
SELECT USECOUNT FROM HOLDING WHERE ItemID = @itemID and LIBID = @LibID and ACQUIREDDATE = @cDate
END


go
/******/
Create PROCEDURE [dbo].[FPT_SP_CIR_LIBLOCUSER_SEL](@intUserID int,@intLibID int)
AS
	SELECT CODE + ':' + SYMBOL AS LOCNAME, B.ID AS ID, REPLACE(CAST(A.ID AS CHAR(3)) + ':' + CAST(B.ID AS CHAR(3)), ' ', '') AS GroupID, A.ID AS LibID, B.Symbol, A.Code
	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C 
	WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID = @intUserID AND B.LibID = @intLibID
	ORDER BY B.LibID, B.Symbol


go	
/******/
Create PROCEDURE [dbo].[FPT_SP_GET_COPYNUMBER_STRING] (@libid int, @acqdate varchar(50), @price real, @itemid int)
AS
DECLARE @sql varchar(50)
SET @sql = ''+CONVERT (varchar(10), @acqdate, 21)
BEGIN
	SELECT distinct ItemID,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID and LibID = @libid and Price = @price AND AcquiredDate = @sql
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
where D2.ItemID =@itemid
END


go
/******/
Create PROCEDURE [dbo].[FPT_SP_GET_HOLDING_BY_LOCATIONID_lan12] (@LibID int, @LocID int, @POID int, @StartDate date, @EndDate date, @OrderBy varchar(10))
AS
if @LocID =0 or @LocID is null
BEGIN
if @OrderBy = 'asc'
	BEGIN
	
		if @StartDate is null AND @EndDate is null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END	
		ELSE IF @StartDate is null AND @EndDate is null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID and F.FieldCode = 245 and A.POID =@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and A.POID=@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and A.POID=@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
			AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and A.POID=@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
	END
	------------------------
	ELSE IF @OrderBy = 'desc'
	BEGIN
	if @StartDate is null AND @EndDate is null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END	
	ELSE IF @StartDate is null AND @EndDate is null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
		AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
END
	
END
--- CHECK LocID---------------------------------------------
else
BEGIN
if @OrderBy = 'asc'
	BEGIN
	
		if @StartDate is null AND @EndDate is null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END	
		ELSE IF @StartDate is null AND @EndDate is null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID and F.FieldCode = 245 and A.POID =@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and A.POID=@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and A.POID=@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
			AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and A.POID=@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
	END
	------------------------
	ELSE IF @OrderBy = 'desc'
	BEGIN
	if @StartDate is null AND @EndDate is null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END	
	ELSE IF @StartDate is null AND @EndDate is null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
		AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
END
	
END



go
/******/
Create PROCEDURE [dbo].[FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE] (@ItemID int, @AcqDate Date)
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID AND D1.ACQUIREDDATE = CONVERT (varchar(10), @AcqDate, 21) AND D1.ItemID = @ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
where D2.ItemID = @ItemID
GROUP BY ItemID
END

go
/******/
Create PROCEDURE [dbo].[SP_HOLDING_LIBLOCUSER_SEL](@intUserID int,@intLibID int)
AS
	SELECT CODE + ':' + SYMBOL AS LOCNAME, B.ID AS ID, REPLACE(CAST(A.ID AS CHAR(3)) + ':' + CAST(B.ID AS CHAR(3)), ' ', '') AS GroupID, A.ID AS LibID, B.Symbol, A.Code
	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_LOCATION C 
	WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocID AND C.UserID = @intUserID AND B.LibID = @intLibID
	ORDER BY B.LibID, B.Symbol

go
/******/
CREATE PROCEDURE [dbo].[FPT_ADMIN_GET_RIGHTS_DENY_ADMIN]
	@intModuleID int
AS

SELECT R.ID, R.[Right] FROM SYS_USER_RIGHT R 
WHERE R.ModuleID = @intModuleID AND R.ID 
NOT IN (
	SELECT U.ID FROM SYS_USER_RIGHT_DETAIL D JOIN SYS_USER_RIGHT U ON D.RightID = U.ID
	WHERE D.UserID = 1 AND U.ModuleID = @intModuleID
)




GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_CIR_LIB_SEL]    Script Date: 07/10/2019 23:47:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FPT_SP_CIR_LIB_SEL]
	@intUserID  int
AS	
	SELECT Code + ': ' + Name as LibName, Code, ID 
	FROM HOLDING_LIBRARY 
	WHERE LocalLib = 1 AND ID IN (SELECT LibID FROM HOLDING_LOCATION, SYS_USER_CIR_LOCATION WHERE SYS_USER_CIR_LOCATION.LocationID = HOLDING_LOCATION.ID AND UserID = @intUserID) ORDER BY Code


GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_CATA_CHECK_EXIST_ITEMNUMBER]    Script Date: 7/1/2019 3:03:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FPT_SP_CATA_CHECK_EXIST_ITEMNUMBER]
-- Purpose: Check exist item by ISBN or ISSN
-- MODIFICATION HISTORY
-- Person      Date    Comments
-- Oanhtn      090305  Create
-- ---------   ------  -------------------------------------------
	@strFieldValue	varchar(50),
	@strFieldCode	varchar(5),
	@lngItemID	int OUT

AS
	SELECT @lngItemID = ItemID FROM CAT_DIC_NUMBER WHERE FieldCode = @strFieldCode AND Number = @strFieldValue
	IF @lngItemID IS NULL SET @lngItemID = 0
	RETURN @lngItemID


/******/
GO
CREATE  PROCEDURE [dbo].[FPT_SP_CATA_GET_DETAILINFOR_OF_ITEM]  
-- Purpose: get all detail information of item (field's values)  
-- MODIFICATION HISTORY  
-- Person      Date    Comments  
-- DOANHDQ    04/07/2019    get all detail information of item (field's values)  
-- ---------   ------  -------------------------------------------  
@strItemIDs VARCHAR(2000),  
@intIsAuthority INT  
-- Declare program variables as shown above  
AS  
DECLARE @strSQL VARCHAR(8000)  
	IF @intIsAuthority = 0  
	BEGIN  
		SET @strItemIDs=REPLACE(@strItemIDs,'','')  
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD000s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD000s WHERE FIELD000s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD000s.FieldCode UNION   
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD100s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD100s WHERE FIELD100s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD100s.FieldCode UNION  
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD200s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD200s WHERE FIELD200s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD200s.FieldCode UNION   
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD300s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD300s WHERE FIELD300s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD300s.FieldCode UNION   
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD400s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD400s WHERE FIELD400s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD400s.FieldCode UNION  
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD500s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD500s WHERE FIELD500s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD500s.FieldCode UNION   
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD600s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD600s WHERE FIELD600s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD600s.FieldCode UNION   
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD700s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD700s WHERE FIELD700s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD700s.FieldCode UNION   
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD800s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD800s WHERE FIELD800s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD800s.FieldCode UNION  
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD900s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD900s WHERE FIELD900s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD900s.FieldCode UNION 
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, Item.ID AS ItemID, '' Ind1, '' Ind2, CAST(Item.NewRecord as varchar(5)) as Content, VietFieldName  FROM MARC_BIB_FIELD, ITEM WHERE Item.ID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = '900' UNION 
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, Item.ID AS ItemID, '' Ind1, '' Ind2, Item.CoverPicture as Content, VietFieldName  FROM MARC_BIB_FIELD, ITEM WHERE Item.ID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = '907' AND CoverPicture IS NOT NULL AND CoverPicture <>'' UNION 
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, Item.ID AS ItemID, '' Ind1, '' Ind2, Item.Cataloguer as Content, VietFieldName  FROM MARC_BIB_FIELD, ITEM WHERE Item.ID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = '911' AND  Cataloguer  IS NOT NULL AND Cataloguer <> '' UNION 
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, Item.ID AS ItemID, '' Ind1, '' Ind2, Item.Code as Content, VietFieldName  FROM MARC_BIB_FIELD, ITEM WHERE Item.ID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = '001' AND  Code  IS NOT NULL AND Code <> '' UNION 
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, Item.ID AS ItemID, '' Ind1, '' Ind2, Item.Reviewer as Content, VietFieldName  FROM MARC_BIB_FIELD, ITEM WHERE Item.ID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = '912' AND Reviewer IS NOT NULL AND Reviewer <> ''       
         ORDER BY ItemID, MARC_BIB_FIELD.FieldCode		
		
	END  
	ELSE SELECT NULL AS VietIndicators, NULL AS Indicators, FieldCode, AuthorityID AS ItemID, Ind1, Ind2, Content, '' as VietFieldName  FROM FIELD_AUTHORITY  WHERE AuthorityID IN( @strItemIDs ) ORDER BY AuthorityID, FieldCode

GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_UPDATE_UNLOCK_PATRON_CARD]  Script Date: 7/22/2019 7:22:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FPT_SP_UPDATE_UNLOCK_PATRON_CARD]
-- Purpose: Update Unlock Locked PatronCard
-- MODIFICATION HISTORY
-- Person      Date    Comments
-- Trinhlv      300804  Create
-- ---------   ------  -------------------------------------------       
	@strPatronCode varchar(500),
	@lockedDay int,
	@Note varchar(1000)
AS
	UPDATE [CIR_PATRON_LOCK] SET LockedDays = @lockedDay, Note = @Note WHERE PatronCode = @strPatronCode



GO
/****** Object:  Table [dbo].[FPT_RECOMMEND]    Script Date: 7/13/2019 5:03:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FPT_RECOMMEND](
	[RecommendID] [varchar](50) NOT NULL,
 CONSTRAINT [PK_FPT_RECOMMEND] PRIMARY KEY CLUSTERED 
(
	[RecommendID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FPT_RECOMMEND_ITEM]    Script Date: 7/13/2019 5:03:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FPT_RECOMMEND_ITEM](
	[RecommendID] [varchar](50) NOT NULL,
	[ItemID] [int] NOT NULL,
 CONSTRAINT [PK_FK_FPT_RecommendID_ItemID] PRIMARY KEY CLUSTERED 
(
	[RecommendID] ASC,
	[ItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FPT_RECOMMEND_ITEM]  WITH CHECK ADD  CONSTRAINT [FK_FPT_RECOMMEND_Item_FPT_RECOMMEND] FOREIGN KEY([RecommendID])
REFERENCES [dbo].[FPT_RECOMMEND] ([RecommendID])
GO
ALTER TABLE [dbo].[FPT_RECOMMEND_ITEM] CHECK CONSTRAINT [FK_FPT_RECOMMEND_Item_FPT_RECOMMEND]
GO
ALTER TABLE [dbo].[FPT_RECOMMEND_ITEM]  WITH CHECK ADD  CONSTRAINT [FK_FPT_RECOMMEND_Item_ITEM] FOREIGN KEY([ItemID])
REFERENCES [dbo].[ITEM] ([ID])
GO
ALTER TABLE [dbo].[FPT_RECOMMEND_ITEM] CHECK CONSTRAINT [FK_FPT_RECOMMEND_Item_ITEM]
GO

GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_BY_RECOMMENDID]    Script Date: 07/23/2019 09:30:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,DucNV>
-- Create date: <16/06/2019,,>
-- Description:	<get data for 'Bao cao danh muc sach nhap' function,,>
-- =============================================
create PROCEDURE [dbo].[FPT_SP_GET_HOLDING_BY_RECOMMENDID] (@LibID int, @LocID int, @reid varchar(50), @StartDate date, @EndDate date, @OrderBy varchar(10))
AS
if @LocID =0 or @LocID is null
BEGIN
if @OrderBy = 'asc'
	BEGIN
	
		if @StartDate is null AND @EndDate is null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END	
		ELSE IF @StartDate is null AND @EndDate is null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID and F.FieldCode = 245 and T.RECOMMENDID =@reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.RECOMMENDID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
			AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
	END
	------------------------
	ELSE IF @OrderBy = 'desc'
	BEGIN
	if @StartDate is null AND @EndDate is null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END	
	ELSE IF @StartDate is null AND @EndDate is null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID and F.FieldCode = 245 and T.RECOMMENDID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.RECOMMENDID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
		AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
END
	
END
--- CHECK LocID---------------------------------------------
else
BEGIN
if @OrderBy = 'asc'
	BEGIN
	
		if @StartDate is null AND @EndDate is null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END	
		ELSE IF @StartDate is null AND @EndDate is null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID and F.FieldCode = 245 and T.RECOMMENDID =@reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.RECOMMENDID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
			AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
	END
	------------------------
	ELSE IF @OrderBy = 'desc'
	BEGIN
	if @StartDate is null AND @EndDate is null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END	
	ELSE IF @StartDate is null AND @EndDate is null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID and F.FieldCode = 245 and T.RECOMMENDID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.RECOMMENDID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
		AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
END
	
END

GO
/****** Object:  StoredProcedure [dbo].[FPT_EDU_GET_SHELF_CONTENT]    ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[FPT_EDU_GET_SHELF_CONTENT]
@itemCode as varchar(100)
AS
BEGIN
	DECLARE @ID as int
	SET  @ID= (SELECT (ID) FROM [ITEM] WHERE Code = @itemCode)
	SELECT FieldCode,  Content FROM Field000s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode,  Content FROM Field100s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field200s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field300s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field400s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field500s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field600s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field700s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field800s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field900s WHERE ItemID = @ID
END





GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_CATA_GET_CONTENTS_OF_ITEMS]    Script Date: 7/9/2019 3:16:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
--FPT_SP_CATA_GET_CONTENTS_OF_ITEMS'1090',0
--Doanhdq created
--use to display all property by  Record
--Fixed : 852 khong lay thong tin ma dang ky ca biet
CREATE        PROCEDURE [dbo].[FPT_SP_CATA_GET_CONTENTS_OF_ITEMS]
	@strItemIDs varchar(1000),
	@intIsAuthority INT
AS

IF @intIsAuthority = 0 
	BEGIN
		--Ldr
		SELECT '000' as IDSort,'Ldr' as FieldCode, '' as Ind, Leader as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		
		--Code
		UNION
		SELECT '001' as IDSort,'001' as FieldCode, '' as Ind, I.Code as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		
		--Field000s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content
		FROM Field000s F, MARC_BIB_FIELD M
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs)  
		
		--Field100s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content 
		FROM Field100s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs)  
		
		--Field200s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content
		FROM Field200s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--Field300s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content 
		FROM Field300s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--Field400s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content
		FROM Field400s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--Field500s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content 
		FROM Field500s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--Field600s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content
		FROM Field600s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--Field700s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content 
		FROM Field700s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--Field800s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content
		FROM Field800s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--Field900s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content
		FROM Field900s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--NewRecord
		UNION
		SELECT '900' as IDSort,'900' as FieldCode, '' as Ind, CAST(I.NewRecord as varchar(5)) as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		
		--CoverPicture
		UNION
		SELECT '907' as IDSort,'907' as FieldCode, '' as Ind, I.CoverPicture as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		AND CoverPicture IS NOT NULL AND CoverPicture <> ''
		
		--Reviewer
		UNION
		SELECT '912' as IDSort,'912' as FieldCode, '' as Ind, I.Reviewer as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		AND Reviewer  IS NOT NULL AND Reviewer <>''
		
		--Cataloguer
		UNION
		SELECT '911' as IDSort,'911' as FieldCode, '' as Ind,  I.Cataloguer as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		AND Cataloguer  IS NOT NULL AND Cataloguer  <>''
		
		--M.Code
		UNION
		SELECT '925' as IDSort,'925' as FieldCode, '' as Ind, M.Code as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		
		--AccessLevel
		UNION
		SELECT '926' as IDSort,'926' as FieldCode, '' as Ind, CAST(I.AccessLevel as varchar(1)) as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		
		--D.TypeCode
		UNION
		SELECT '927' as IDSort,'927' as FieldCode, '' as Ind, D.TypeCode as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
			-- copynumber : 852$j
	    union
	    SELECT distinct '852' as IDSort,'852' as FieldCode, '' as Ind,  '$a' + HLB.code + '$b' + hl.symbol as Content
        FROM HOLDING H, HOLDING_LOCATION HL, HOLDING_LIBRARY HLB WHERE H.ItemID  =@strItemIDs AND H.locationid=HL.ID AND HL.LIBID=HLB.ID

		--ORDER
		
		ORDER BY IDSort
	END
ELSE
	BEGIN
		SELECT '0' as IDSort,'Ldr' as FieldCode, '0' as Ind, Leader as Content
		FROM CAT_AUTHORITY where
		ID IN (@strItemIDs)
		
		UNION
		-- 001 : code
		SELECT '001' as IDSort,'001' as FieldCode, '0' as Ind, Code as Content
		FROM CAT_AUTHORITY where
		ID IN (@strItemIDs)
		
		UNION	
		
		SELECT MA.FieldCode as IDSort,MA.FieldCode, REPLACE(FA.Ind1,' ','#')  + REPLACE(FA.Ind2,' ','#')  as Ind, REPLACE(FA.Content,' ','&nbsp;') as Content
		FROM Field_Authority FA, MARC_Authority_field MA
		WHERE MA.FieldCode = FA.FieldCode
		And AuthorityID IN (@strItemIDs)
		
		UNION	
		-- cataloguer
		SELECT '911' as IDSort,'911' as FieldCode, '0' as Ind, Cataloguer as Content
		FROM CAT_AUTHORITY CA 	
		where CA.ID IN (@strItemIDs)
		
		UNION	
		-- reviewer
		SELECT '912' as IDSort,'912' as FieldCode, '0' as Ind, Reviewer as Content
		FROM CAT_AUTHORITY CA 
		where	
		CA.ID IN (@strItemIDs)
		--ORDER
		
		ORDER BY IDSort;
	END
	


go
-- thêm dữ liệu vào bảng để tạo form biên mục--
INSERT [dbo].[MARC_WORKSHEET] ([ID], [Name], [Creator], [CreatedDate], [LastModifiedDate], [Note]) VALUES (14, N'Mẫu biên mục Sách (2019)', N'Nguyễn Thị Thơi', CAST(N'2019-06-13T00:00:00.000' AS DateTime), CAST(N'2019-06-13T00:00:00.000' AS DateTime), NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'001', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'020$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'022$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'040$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'041$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'044$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'082$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'090$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'090$b', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'100$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'110$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'245$a', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'245$b', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'245$b', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'245$c', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'245$n', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'245$p', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'246$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'250$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'260$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'260$b', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'260$c', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'300$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'300$b', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'300$c', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'300$e', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'490$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'500$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'520$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'650$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'653$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'700$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'852$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'900', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'911', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'925', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'926', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'927', 1, NULL, 0, NULL)

------	


GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_LANGUAGE_DETAILS_STATISTIC]    Script Date: 07/26/2019 20:23:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_LANGUAGE_DETAILS_STATISTIC]
	@strTypeSelect VARCHAR(20),
	@intLibraryID int
AS
BEGIN	
	IF @strTypeSelect='ITEM'
		BEGIN
			IF NOT @intLibraryID = 0
				SELECT sum(A.Total) as Total,A.ISOCode FROM (SELECT Count(Distinct A.ItemID) AS Total,ISNULL(C.ISOCode,'Không XĐ')AS ISOCode FROM HOLDING A,ITEM_LANGUAGE B,CAT_DIC_LANGUAGE C WHERE B.LanguageID=C.ID AND A.ItemID=B.ItemID AND A.LibID = @intLibraryID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.ISOCode) A GROUP BY A.ISOCode ORDER BY Total DESC
			ELSE 
				SELECT sum(A.Total) as Total,A.ISOCode FROM (SELECT Count(*) AS Total,ISNULL(B.ISOCode,'Không XĐ')AS ISOCode FROM ITEM_LANGUAGE A,CAT_DIC_LANGUAGE B  WHERE A.LanguageID=B.ID AND Right(A.FieldCode,2)='$a'  GROUP BY B.ISOCode) A GROUP BY A.ISOCode ORDER BY Total DESC
		END	
	IF @strTypeSelect='COPY'
		BEGIN
			IF NOT @intLibraryID = 0
				SELECT sum(A.Total) as Total,A.ISOCode FROM (SELECT Count(*) AS Total,ISNULL(C.ISOCode,'Không XĐ')AS ISOCode FROM HOLDING A,ITEM_LANGUAGE B,CAT_DIC_LANGUAGE C WHERE B.LanguageID=C.ID AND A.ItemID=B.ItemID AND A.LibID = @intLibraryID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.ISOCode) A GROUP BY A.ISOCode ORDER BY Total DESC
			ELSE 
				SELECT sum(A.Total) as Total,A.ISOCode FROM (SELECT Count(*) AS Total,ISNULL(C.ISOCode,'Không XĐ')AS ISOCode FROM HOLDING A,ITEM_LANGUAGE B,CAT_DIC_LANGUAGE C WHERE B.LanguageID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.ISOCode) A GROUP BY A.ISOCode ORDER BY Total DESC
		END
	
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_LANGUAGE_STATISTIC]    Script Date: 07/26/2019 20:24:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_LANGUAGE_STATISTIC]
	@intLibraryID int
AS
BEGIN
	BEGIN
		IF NOT @intLibraryID = 0
			SELECT A.*,B.* FROM(SELECT  Count(Distinct ItemID) AS TotalBook FROM HOLDING WHERE LibID = @intLibraryID) A,(SELECT  Count (*) AS TotalCopies FROM HOLDING WHERE LibID = @intLibraryID) B    
		ELSE 
			SELECT A.*,B.* FROM(SELECT  Count(*) AS TotalBook FROM ITEM) A,(SELECT  Count (*) AS TotalCopies FROM HOLDING) B    
	END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_AUTHOR]    Script Date: 07/26/2019 20:24:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO TÁC GIẢ
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_AUTHOR]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM HOLDING A,ITEM_AUTHOR B,CAT_DIC_AUTHOR C 
			WHERE B.AuthorID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ')AS AccessEntry 
				FROM ITEM_AUTHOR B,CAT_DIC_AUTHOR C 
			WHERE B.AuthorID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_BBK]    Script Date: 07/26/2019 20:24:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO BBK
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_BBK]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_BBK B,CAT_DIC_CLASS_BBK C 
			WHERE B.BBKID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_BBK B,CAT_DIC_CLASS_BBK C 
			WHERE B.BBKID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END


GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_COUNTRY]    Script Date: 07/26/2019 20:24:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO COUNTRY
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_COUNTRY]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_COUNTRY B,CAT_DIC_COUNTRY C 
			WHERE B.CountryID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_COUNTRY B,CAT_DIC_COUNTRY C 
			WHERE B.CountryID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END


GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DDC]    Script Date: 07/26/2019 20:24:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO DDC
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DDC]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_DDC B,CAT_DIC_CLASS_DDC C 
			WHERE B.DDCID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_DDC B,CAT_DIC_CLASS_DDC C 
			WHERE B.DDCID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC40]    Script Date: 07/26/2019 20:24:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO Chỉ số ISBN
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC40]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_DICTIONARY40 B,DICTIONARY40 C 
			WHERE B.DICTIONARY40ID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_DICTIONARY40 B,DICTIONARY40 C 
			WHERE B.DICTIONARY40ID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END


GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC41]    Script Date: 07/26/2019 20:25:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO Giá tiền
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC41]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_DICTIONARY41 B,DICTIONARY41 C 
			WHERE B.DICTIONARY41ID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_DICTIONARY41 B,DICTIONARY41 C 
			WHERE B.DICTIONARY41ID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END


GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC42]    Script Date: 07/26/2019 20:25:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO Khổ cỡ
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC42]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_DICTIONARY42 B,DICTIONARY42 C 
			WHERE B.DICTIONARY42ID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$c'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_DICTIONARY42 B,DICTIONARY42 C 
			WHERE B.DICTIONARY42ID=C.ID AND Right(B.Fieldcode,2)='$c'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC43]    Script Date: 07/26/2019 20:25:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO Mã xếp giá
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC43]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_DICTIONARY43 B,DICTIONARY43 C 
			WHERE B.DICTIONARY43ID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_DICTIONARY43 B,DICTIONARY43 C 
			WHERE B.DICTIONARY43ID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_ITEMTYPE_NEW]    Script Date: 07/26/2019 20:25:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO DẠNG TÀI LIỆU
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_ITEMTYPE_NEW]
@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL AS Total, B.CODE AS AccessEntry, B.NAME FROM(SELECT COUNT(H.ITEMID) AS TOTAL, I.TYPEID AS ID
			FROM HOLDING H, ITEM I WHERE H.ITEMID = I.ID
			GROUP BY I.TYPEID) A, (SELECT DISTINCT(I.TYPEID) AS ID, C.TYPECODE AS CODE, ISNULL(C.TYPENAME,'Không XĐ') AS NAME FROM ITEM I, CAT_DIC_ITEM_TYPE C WHERE I.TYPEID = C.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL as Total, B.CODE AS AccessEntry, B.NAME FROM(SELECT COUNT(DISTINCT H.ITEMID) AS TOTAL, I.TYPEID AS ID
			FROM HOLDING H, ITEM I WHERE H.ITEMID = I.ID
			GROUP BY I.TYPEID) A, (SELECT DISTINCT(I.TYPEID) AS ID, C.TYPECODE AS CODE, ISNULL(C.TYPENAME,'Không XĐ') AS NAME 
			FROM ITEM I, CAT_DIC_ITEM_TYPE C WHERE I.TYPEID = C.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_KEYWORD]    Script Date: 07/26/2019 20:25:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO TỪ KHOÁ
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_KEYWORD]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM HOLDING A,ITEM_KEYWORD B,CAT_DIC_KEYWORD C 
			WHERE B.KeyWordID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_KEYWORD B,CAT_DIC_KEYWORD C 
			WHERE B.KeyWordID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_LANGUAGE]    Script Date: 07/26/2019 20:25:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO LANGUAGE
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_LANGUAGE]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_LANGUAGE B,CAT_DIC_LANGUAGE C 
			WHERE B.LanguageID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_LANGUAGE B,CAT_DIC_LANGUAGE C 
			WHERE B.LanguageID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_LIBRARY_NEW]    Script Date: 07/26/2019 20:26:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO DẠNG TÀI LIỆU
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_LIBRARY_NEW]
	@intType int
AS
BEGIN
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL AS Total, B.CODE AS AccessEntry, B.NAME FROM(SELECT COUNT(H.ITEMID) AS TOTAL, H.LIBID AS ID
			FROM HOLDING H, ITEM I WHERE H.ITEMID = I.ID
			GROUP BY H.LIBID) A, (SELECT DISTINCT(H.LIBID) AS ID, L.CODE AS CODE, ISNULL(L.ACCESSENTRY,'Không XĐ') AS NAME FROM HOLDING H, HOLDING_LIBRARY L WHERE H.LIBID = L.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL AS Total, B.CODE AS AccessEntry, B.NAME FROM(SELECT COUNT(DISTINCT H.ITEMID) AS TOTAL, H.LIBID AS ID
			FROM HOLDING H, ITEM I WHERE H.ITEMID = I.ID
			GROUP BY H.LIBID) A, (SELECT DISTINCT(H.LIBID) AS ID, L.CODE AS CODE, ISNULL(L.ACCESSENTRY,'Không XĐ') AS NAME FROM HOLDING H, HOLDING_LIBRARY L WHERE H.LIBID = L.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
	
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_LOC]    Script Date: 07/26/2019 20:26:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO LOC
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_LOC]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_LOC B,CAT_DIC_CLASS_LOC C 
			WHERE B.LOCID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_LOC B,CAT_DIC_CLASS_LOC C 
			WHERE B.LOCID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END


GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_MEDIUM_NEW]    Script Date: 07/26/2019 20:26:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO VẬT MANG TIN
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_MEDIUM_NEW]
	@intType int
AS
BEGIN
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL as Total, B.CODE, B.NAME as AccessEntry FROM(SELECT COUNT(I.MEDIUMID) AS TOTAL, I.MEDIUMID AS ID
			FROM HOLDING H, ITEM I WHERE H.ITEMID = I.ID
			GROUP BY I.MEDIUMID) A, (SELECT DISTINCT(I.MEDIUMID) AS ID, C.CODE AS CODE, ISNULL(C.DESCRIPTION,C.ACCESSENTRY) AS NAME FROM ITEM I, CAT_DIC_MEDIUM C WHERE I.MEDIUMID = C.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL as Total, B.CODE, B.NAME as AccessEntry FROM(SELECT COUNT(I.MEDIUMID) AS TOTAL, I.MEDIUMID AS ID
			FROM ITEM I
			GROUP BY I.MEDIUMID) A, (SELECT DISTINCT(I.MEDIUMID) AS ID, C.CODE AS CODE, ISNULL(C.DESCRIPTION,C.ACCESSENTRY) AS NAME FROM ITEM I, CAT_DIC_MEDIUM C WHERE I.MEDIUMID = C.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_NLM]    Script Date: 07/26/2019 20:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO NLM
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_NLM]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_NLM B,CAT_DIC_CLASS_NLM C 
			WHERE B.NLMID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_NLM B,CAT_DIC_CLASS_NLM C 
			WHERE B.NLMID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_OAI_SET]    Script Date: 07/26/2019 20:26:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO OAI Set
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_OAI_SET]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_OAI_SET B,CAT_DIC_OAI_SET C 
			WHERE B.OaiID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_OAI_SET B,CAT_DIC_OAI_SET C 
			WHERE B.OaiID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_PUBLISHER]    Script Date: 07/26/2019 20:26:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO NHÀ XUẤT BẢN
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_PUBLISHER]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM HOLDING A,ITEM_PUBLISHER B,CAT_DIC_PUBLISHER C 
			WHERE B.PublisherID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$b'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_PUBLISHER B,CAT_DIC_PUBLISHER C 
			WHERE B.PublisherID=C.ID AND Right(B.Fieldcode,2)='$b'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_SERIALS]    Script Date: 07/26/2019 20:26:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO SERIALS
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_SERIALS]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_SERIES B,CAT_DIC_SERIES C 
			WHERE B.SeriesID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_SERIES B,CAT_DIC_SERIES C 
			WHERE B.SeriesID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_SH]    Script Date: 07/26/2019 20:27:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO TIÊU ĐỀ ĐỀ MỤC
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_SH]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM HOLDING A,ITEM_SH B,CAT_DIC_SH C 
				WHERE B.SHID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ')AS AccessEntry 
				FROM ITEM_SH B,CAT_DIC_SH C 
				WHERE B.SHID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END


GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_THESIS_SUBJECT]    Script Date: 07/26/2019 20:27:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO Chuyen_nganh_luan_an
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_THESIS_SUBJECT]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_THESIS_SUBJECT B,CAT_DIC_THESIS_SUBJECT C 
			WHERE B.SubjectID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_THESIS_SUBJECT B,CAT_DIC_THESIS_SUBJECT C 
			WHERE B.SubjectID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_UDC]    Script Date: 07/26/2019 20:27:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO UDC
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_UDC]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_UDC B,CAT_DIC_CLASS_UDC C 
			WHERE B.UDCID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_UDC B,CAT_DIC_CLASS_UDC C 
			WHERE B.UDCID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_GET_PATRON_LOCK_STATISTIC]    Script Date: 07/27/2019 14:34:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[FPT_GET_PATRON_LOCK_STATISTIC]
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
	DECLARE @strSql nvarchar(1000)
	DECLARE @strJoinSQL nvarchar(1000)
	DECLARE @strLikeSql nvarchar(1000)
	
	SET @strSql = 'SELECT CPL.PatronCode, CPL.StartedDate, CPL.Note, CP.FirstName + '' '' + CP.MiddleName + '' '' + CP.LastName as FullName, CPL.StartedDate + CPL.LockedDays as FinishDate, CPL.LockedDays '
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


GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_REMOVED]    Script Date: 07/28/2019 10:32:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Purpose: Select holidng_remove information
-- In: some infor
-- Creator: Vantd
-- CreatedDate: 09/03/2005
-- LastModifiedDate: 02/12/2005 by Sondp
CREATE PROCEDURE [dbo].[FPT_SP_GET_HOLDING_REMOVED]
	@intLibID	NVARCHAR(100),
	@intLocID	NVARCHAR(100),
	@strShelf	NVARCHAR(10),
	@strCopyNumber	VARCHAR(33),
	@strCallNumber	NVARCHAR(32),
	@strVolume	NVARCHAR(32),
	@strTitle	NVARCHAR(1000)
AS
	DECLARE @strSQL NVARCHAR(4000)
	DECLARE @strWhere NVARCHAR(4000)
	DECLARE @strTable	NVARCHAR(1000)
	SET @strSQL='SELECT HOLDING_REMOVED.*,LEFT(FIELD200S.Content,50) AS Content,
		HOLDING_REMOVED.REASON as REASON_ID,HOLDING_REMOVE_REASON.REASON '

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
		SET @strSQL=@strSQL + ','' '' AS LibName'

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
	SET @strTable = @strTable + ' '

	SET @strSQL=@strSQL + ', hl.Symbol AS LocName'
PRINT @strSQL + @strTable + @strWhere
	EXECUTE(@strSQL + @strTable + @strWhere)
	
	
	GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_REMOVED_PAGING]    Script Date: 7/24/2019 02:52:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Purpose: Select holidng_remove information
-- In: some infor
-- Creator: Vantd
-- CreatedDate: 09/03/2005
-- LastModifiedDate: 02/12/2005 by Sondp
CREATE PROCEDURE [dbo].[FPT_SP_GET_HOLDING_REMOVED_PAGING]
	@intLibID	NVARCHAR(100),
	@intLocID	NVARCHAR(100),
	@strShelf	NVARCHAR(10),
	@strCopyNumber	VARCHAR(33),
	@strCallNumber	NVARCHAR(32),
	@strVolume	NVARCHAR(32),
	@strTitle	NVARCHAR(1000),
	@numberIndex NVARCHAR(500),
	@numberRecordPerPage NVARCHAR(500)
AS
	DECLARE @strSQL NVARCHAR(4000)
	DECLARE @strWhere NVARCHAR(4000)
	DECLARE @strTable	NVARCHAR(1000)
	DECLARE @strPaging NVARCHAR(1000)
	DECLARE @numberIndexs int
	DECLARE @numberRecordPerPages int

	SET @numberIndexs = CAST(@numberIndex as int)
	SET @numberRecordPerPages = CAST(@numberRecordPerPage as int)


	SET @strSQL='SELECT HOLDING_REMOVED.*,LEFT(FIELD200S.Content,50) AS Content,
		HOLDING_REMOVED.REASON as REASON_ID,HOLDING_REMOVE_REASON.REASON '

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
		SET @strSQL=@strSQL + ','' '' AS LibName'

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
	SET @strTable = @strTable + ' '

	SET @strSQL=@strSQL + ', hl.Symbol AS LocName'

	SET @strPaging = ' ORDER BY HOLDING_REMOVED.ID ASC
						OFFSET ' + CAST(@numberRecordPerPages*(@numberIndexs-1) as char)
						+' ROWS FETCH NEXT '+ @numberRecordPerPage +' ROWS ONLY;'


PRINT @strSQL + @strTable + @strWhere + @strPaging
	EXECUTE(@strSQL + @strTable + @strWhere + @strPaging)


GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_ITEM]    Script Date: 7/28/2019 04:21:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<ducnv>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ DANH MỤC SÁCH NHẬP
-- =============================================
CREATE  PROCEDURE [dbo].[FPT_SP_GET_ITEM]

      @strFromDate VARCHAR(30),

      @strToDate  VARCHAR(30),

      @intLocationID    int,
      
      @intLibraryID int

AS   

      DECLARE @strSQL NVARCHAR(1000)

      SET @strSQL=''

      SET @strSQL=@strSQL + 'SELECT I.ID,I.Code, U.DKCB, F.Content 
      FROM ITEM I
      join FIELD200S F on I.ID=F.ITEMID
join (SELECT distinct ItemID ,
STUFF(( SELECT  '', '' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('''')
), 1, 1, '''') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on I.ID = U.ItemID
WHERE FIELDCODE=''245'' AND (I.TYPEID=1 OR I.TypeID=15) '

      If @strFromDate<>''

            SET @strSQL=@strSQL + ' AND I.CreatedDate>=CONVERT(VARCHAR, '''+@strFromDate+''', 21)'

      If @strToDate<>''

            SET @strSQL=@strSQL + ' AND I.CreatedDate<=CONVERT(VARCHAR, '''+@strToDate+''', 21)'

      If @intLocationID <>0

            SET @strSQL=@strSQL + ' AND I.ID IN (SELECT ITEMID FROM HOLDING WHERE LocationID='+ convert(nvarchar,@intLocationID) +')'
            
       If @intLocationID =0

            SET @strSQL=@strSQL + ' AND I.ID IN (SELECT ITEMID FROM HOLDING WHERE LibID='+ convert(nvarchar,@intLibraryID) +')'


    --print(@strSQL)

      EXEC(@strSQL)
      

GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_REMOVED_PAGING_v2]    Script Date: 7/28/2019 04:21:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Purpose: Select holidng_remove information
-- In: some infor
-- Creator: Vantd
-- CreatedDate: 09/03/2005
-- LastModifiedDate: 02/12/2005 by Sondp
CREATE PROCEDURE [dbo].[FPT_SP_GET_HOLDING_REMOVED_PAGING_v2]
	@intLibID	NVARCHAR(100),
	@intLocID	NVARCHAR(100),
	@strShelf	NVARCHAR(10),
	@strCopyNumber	VARCHAR(33),
	@strCallNumber	NVARCHAR(32),
	@strVolume	NVARCHAR(32),
	@strTitle	NVARCHAR(1000),
	@numberIndex NVARCHAR(500),
	@numberRecordPerPage NVARCHAR(500)
AS
	DECLARE @strSQL NVARCHAR(4000)
	DECLARE @strWhere NVARCHAR(4000)
	DECLARE @strTable	NVARCHAR(1000)
	DECLARE @strPaging NVARCHAR(1000)
	DECLARE @numberIndexs int
	DECLARE @numberRecordPerPages int
	DECLARE @strfinal NVARCHAR(4000)

	SET @numberIndexs = CAST(@numberIndex as int)
	SET @numberRecordPerPages = CAST(@numberRecordPerPage as int)


	SET @strSQL='SELECT ROW_NUMBER() OVER (ORDER BY hr.ID) AS Seq, hr.*,LEFT(FIELD200S.Content,50) AS Content,
		hr.REASON as REASON_ID '

	SET @strTable=' FROM (HOLDING_REMOVED hr Join HOLDING_LOCATION hl on hl.id = hr.LocationID) ,FIELD200S,HOLDING_REMOVE_REASON hrr '

	SET @strWhere=' WHERE Field200s.FieldCode=''245'' AND FIELD200S.ItemID=hr.ItemID 
		AND hrr.ID=hr.Reason'

	IF @strTitle<>'' 
	BEGIN
		SET @strTable=@strTable + ', ITEM_TITLE'	
		SET @strWhere=@strWhere + ' AND hr.ItemID=ITEM_TITLE.ItemID AND ITEM_TITLE.FieldCode=''245'''
	END

	IF @intLibID<>0 
		BEGIN
			SET @strWhere= @strWhere + ' AND HOLDING_LIBRARY.ID=hr.LibID 
			AND hr.LibID=' + RTrim(CAST(@intLibID AS CHAR))

			IF PATINDEX('%,HOLDING_LIBRARY%',@strTable)=0
				SET @strTable= @strTable + ',HOLDING_LIBRARY'
			SET @strSQL=@strSQL + ',Code AS LibName'
		END
	ELSE
		SET @strSQL=@strSQL + ','' '' AS LibName'

	IF @intLocID<>0 
		BEGIN
			SET @strWhere= @strWhere + ' AND HOLDING_LOCATION.ID=hr.LocationID 
			AND hr.LocationID=' + RTrim(CAST(@intLocID AS CHAR))
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

	SET @strTable = @strTable + ' '

	SET @strSQL=@strSQL + ', hl.Symbol AS LocName'

	SET @strfinal = 'select a.*, hrr.REASON as REASON_DETAIL from ('+ @strSQL + @strTable + @strWhere + ' ) 
					a join HOLDING_REMOVE_REASON hrr on a.REASON_ID = hrr.ID 
					where a.Seq between ' + CAST(@numberRecordPerPages*(@numberIndexs-1)+1 as char)
						+  ' and ' + CAST(@numberRecordPerPages*(@numberIndexs) as char)
PRINT @strfinal
	EXECUTE(@strfinal)




GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_REMOVED_TOTAL_AMOUNT]    Script Date: 7/24/2019 02:52:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Purpose: Select holidng_remove information
-- In: some infor
-- Creator: Vantd
-- CreatedDate: 09/03/2005
-- LastModifiedDate: 02/12/2005 by Sondp
CREATE PROCEDURE [dbo].[FPT_SP_GET_HOLDING_REMOVED_TOTAL_AMOUNT]
	@intLibID	NVARCHAR(100),
	@intLocID	NVARCHAR(100),
	@strShelf	NVARCHAR(10),
	@strCopyNumber	VARCHAR(33),
	@strCallNumber	NVARCHAR(32),
	@strVolume	NVARCHAR(32),
	@strTitle	NVARCHAR(1000)
AS
	DECLARE @strSQL NVARCHAR(4000)
	DECLARE @strWhere NVARCHAR(4000)
	DECLARE @strTable	NVARCHAR(1000)
	SET @strSQL='SELECT COUNT(HOLDING_REMOVED.ID) as Total '

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
	SET @strTable = @strTable + ' '

PRINT @strSQL + @strTable + @strWhere
	EXECUTE(@strSQL + @strTable + @strWhere)





      GO
/****** Object:  StoredProcedure [dbo].[FPT_COUNT_COPYNUMBER_BY_ITEMID]    Script Date: 07/28/2019 10:38:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<ducnv>
-- Create date: <Create Date,,>
-- Description:	<ĐẾM SỐ LƯỢNG ĐANG KÝ CÁ BIỆT TRONG KHO,,>
-- =============================================
Create PROCEDURE [dbo].[FPT_COUNT_COPYNUMBER_BY_ITEMID] 
@itemID int,
 @intLocationID int,
  @intLibraryID int
	-- Add the parameters for the stored procedure here
	
AS
DECLARE @strSQL NVARCHAR(1000)
SET @strSQL=''

      SET @strSQL=@strSQL +'SELECT COUNT(COPYNUMBER) as SLuong FROM HOLDING WHERE ITEMID = ' +convert(nvarchar,@itemID)

	If @intLocationID <>0
		 SET @strSQL=@strSQL +' AND  LocationID = ' +convert(nvarchar,@intLocationID)
	If @intLocationID =0
		SET @strSQL=@strSQL +' AND LibID = ' + convert(nvarchar,@intLibraryID)
--print(@strSQL)

      EXEC(@strSQL)


GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_REMOVED_WITH_ID]    Script Date: 7/24/2019 02:53:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FPT_SP_GET_HOLDING_REMOVED_WITH_ID]
	@strID	NVARCHAR(100)	
AS
	DECLARE @strSQL NVARCHAR(4000)
	DECLARE @strWhere NVARCHAR(4000)
	DECLARE @strTable	NVARCHAR(1000)
	SET @strSQL='SELECT HOLDING_REMOVED.*,LEFT(FIELD200S.Content,50) AS Content,
		HOLDING_REMOVED.REASON as REASON_ID,HOLDING_REMOVE_REASON.REASON '
	SET @strTable=' FROM (HOLDING_REMOVED Join HOLDING_LOCATION hl on hl.id = HOLDING_REMOVED.LocationID) ,FIELD200S,HOLDING_REMOVE_REASON '
	SET @strWhere=' WHERE Field200s.FieldCode=''245'' AND FIELD200S.ItemID=HOLDING_REMOVED.ItemID 
		AND HOLDING_REMOVE_REASON.ID=HOLDING_REMOVED.Reason and HOLDING_REMOVED.ID = ' + @strID
	SET @strTable = @strTable + ' '
	SET @strSQL=@strSQL + ', hl.Symbol AS LocName'
PRINT @strSQL + @strTable + @strWhere
	EXECUTE(@strSQL + @strTable + @strWhere)
	
	
	
	
	GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_HOLDING_REMOVED_ITEM_DEL]    Script Date: 7/26/2019 12:28:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[FPT_SP_HOLDING_REMOVED_ITEM_DEL]
-- Purpose: Del data in tables HOLDING_REMOVED_...
-- ---------   ------  -------------------------------------------
 @strId	varchar(150)
AS
BEGIN TRAN DELETE_TRAN
	DELETE FROM HOLDING_REMOVED WHERE ID = @strId
IF @@Error>0 
BEGIN
	ROLLBACK TRAN DELETE_TRAN
	RETURN
END
COMMIT TRAN




GO
/****** Object:  StoredProcedure [dbo].[FPT_COUNT_COPYNUMBER_ONLOAN]    Script Date: 07/28/2019 10:41:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<DUCNV>
-- Create date: <Create Date,,>
-- Description:	<SỐ LƯỢNG ĐANG MƯỢN,,>
-- =============================================
Create PROCEDURE [dbo].[FPT_COUNT_COPYNUMBER_ONLOAN] 
@itemID int,
 @intLocationID int,
  @intLibraryID int
	-- Add the parameters for the stored procedure here
	
AS
DECLARE @strSQL NVARCHAR(1000)
SET @strSQL=''

      SET @strSQL=@strSQL +'SELECT COUNT(COPYNUMBER) as SLuong FROM CIR_LOAN WHERE ITEMID = ' +convert(nvarchar,@itemID)

	If @intLocationID <>0
		 SET @strSQL=@strSQL + ' AND ITEMID IN (SELECT ITEMID FROM HOLDING WHERE LocationID='+ convert(nvarchar,@intLocationID) +')'
	If @intLocationID =0
		SET @strSQL=@strSQL + ' AND ITEMID IN (SELECT ITEMID FROM HOLDING WHERE LibID='+ convert(nvarchar,@intLibraryID) +')'
--print(@strSQL)

      EXEC(@strSQL)
	  
	 
GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_HOLDING_LIBLOCUSER_SEL]    Script Date: 7/26/2019 01:23:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[FPT_SP_HOLDING_LIBLOCUSER_SEL](@intLibID int)
AS
	SELECT CODE + ':' + SYMBOL AS LOCNAME, 
		B.ID AS ID, REPLACE(CAST(A.ID AS CHAR(3)) + ':' + CAST(B.ID AS CHAR(3)), ' ', '') AS GroupID, 
		A.ID AS LibID, B.Symbol, A.Code
	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B 
	WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.LibID = @intLibID
	ORDER BY B.LibID, B.Symbol	 
	  
