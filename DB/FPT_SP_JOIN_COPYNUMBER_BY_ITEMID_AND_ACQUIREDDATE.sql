USE [Libol]
GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE]    Script Date: 07/12/2019 09:13:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE] (@ItemID int, @AcqDate Date)
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

