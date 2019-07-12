USE [Libol]
GO
/****** Object:  StoredProcedure [dbo].[FPT_SELECT_USECOUNT2]    Script Date: 07/12/2019 09:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[FPT_SELECT_USECOUNT2] (@LibID int, @itemID int, @cDate date)
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
SELECT USECOUNT FROM HOLDING WHERE ItemID = @itemID and LIBID = @LibID and ACQUIREDDATE = @cDate
END
