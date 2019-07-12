USE [Libol]
GO
/****** Object:  StoredProcedure [dbo].[FPT_CIR_YEAR_STATISTIC]    Script Date: 07/10/2019 23:50:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




--purpose: select data to Statistic 
--creator: AnNXT
--createdDate: 03/07/2019
ALTER PROCEDURE [dbo].[FPT_CIR_YEAR_STATISTIC] 
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


