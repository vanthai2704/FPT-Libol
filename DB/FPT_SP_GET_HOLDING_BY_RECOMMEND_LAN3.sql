USE [Libol]
GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_BY_RECOMMEND_LAN3]    Script Date: 07/12/2019 10:54:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,DucNV>
-- Create date: <16/06/2019,,>
-- Description:	<get data for 'Bao cao danh muc sach nhap' function,,>
-- =============================================
ALTER PROCEDURE [dbo].[FPT_SP_GET_HOLDING_BY_RECOMMEND_LAN3] (@LibID int, @LocID int, @reid varchar(30), @StartDate date, @EndDate date, @OrderBy varchar(10))
AS
if @LocID =0 or @LocID is null
BEGIN
if @OrderBy = 'asc'
	BEGIN
	
		if @StartDate is null AND @EndDate is null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID and F.FieldCode = 245 and T.REID =@reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.REID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.REID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
			AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.REID = @reid
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID and F.FieldCode = 245 and T.REID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.REID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.REID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
		AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.REID = @reid
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID and F.FieldCode = 245 and T.REID =@reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.REID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.REID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
			AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.REID = @reid
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID and F.FieldCode = 245 and T.REID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.REID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.REID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
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
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
		AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.REID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
END
	
END