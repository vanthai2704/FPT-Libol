USE [Libol]
GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_CIR_LIB_SEL]    Script Date: 07/10/2019 23:47:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






ALTER PROCEDURE [dbo].[FPT_SP_CIR_LIB_SEL]
	@intUserID  int
AS	
	SELECT Code + ': ' + Name as LibName, Code, ID 
	FROM HOLDING_LIBRARY 
	WHERE LocalLib = 1 AND ID IN (SELECT LibID FROM HOLDING_LOCATION, SYS_USER_CIR_LOCATION WHERE SYS_USER_CIR_LOCATION.LocationID = HOLDING_LOCATION.ID AND UserID = @intUserID) ORDER BY Code

