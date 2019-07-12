USE [Libol]
GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_CIR_LIBLOCUSER_SEL]    Script Date: 07/10/2019 23:58:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[FPT_SP_CIR_LIBLOCUSER_SEL](@intUserID int,@intLibID int)
AS
	SELECT CODE + ':' + SYMBOL AS LOCNAME, B.ID AS ID, REPLACE(CAST(A.ID AS CHAR(3)) + ':' + CAST(B.ID AS CHAR(3)), ' ', '') AS GroupID, A.ID AS LibID, B.Symbol, A.Code
	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C 
	WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID = @intUserID AND B.LibID = @intLibID
	ORDER BY B.LibID, B.Symbol
