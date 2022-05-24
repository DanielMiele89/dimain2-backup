-- =============================================
-- Author:		JEA
-- Create date: 21/06/2013
-- Description:	Clears down SchemeUpliftTrans
-- =============================================
CREATE PROCEDURE [MI].[SchemeUpliftTrans_Cleardown] 
	(@FileID INT=0)
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	IF EXISTS(SELECT * FROM sys.tables WHERE name = 'SchemeUpliftTrans_Backup' AND Schema_ID = 6)
	BEGIN
		DROP TABLE Relational.SchemeUpliftTrans_Backup
	END

	ALTER TABLE Relational.SchemeUpliftTrans DROP CONSTRAINT [DF_Relational_SchemeUpliftTrans_ExcludeTime]
	ALTER TABLE Relational.SchemeUpliftTrans DROP CONSTRAINT [FK_SchemeUpliftTrans_SchemeUpliftTransWeek]

	EXEC sp_rename 'Relational.SchemeUpliftTrans.PK_SchemeUpliftTrans', 'PK_SchemeUpliftTrans_Backup'

	EXEC sp_rename 'Relational.SchemeUpliftTrans.IX_Relational_SchemeUpliftTrans_Cover', 'IX_Relational_SchemeUpliftTrans_Backup_Cover'

	EXEC sp_rename 'Relational.SchemeUpliftTrans.IX_Relational_SchemeUpliftTrans_MonthlyReportFacilitate', 'IX_Relational_SchemeUpliftTrans_Backup_MonthlyReportFacilitate'

	EXEC sp_rename 'Relational.SchemeUpliftTrans.IX_Relational_SchemeUpliftTrans_MemberSalesFacilitate', 'IX_Relational_SchemeUpliftTrans_Backup_MemberSalesFacilitate'

	EXEC sp_rename 'Relational.SchemeUpliftTrans', 'SchemeUpliftTrans_Backup'

	CREATE TABLE [Relational].[SchemeUpliftTrans](
		[FileID] [int] NOT NULL,
		[RowNum] [int] NOT NULL,
		[Amount] [money] NOT NULL,
		[AddedDate] [date] NULL,
		[FanID] [int] NOT NULL,
		[OutletID] [int] NOT NULL,
		[PartnerID] [int] NOT NULL,
		[IsOnline] [bit] NOT NULL,
		[weekid] [int] NULL,
		[ExcludeTime] [bit] NOT NULL,
		[TranDate] [date] NOT NULL,
		[IsRetailReport] [bit] NOT NULL,
		[PaymentTypeID] [TINYINT] NOT NULL,
	 CONSTRAINT [PK_SchemeUpLiftTrans] PRIMARY KEY CLUSTERED 
	(
		[FileID] ASC,
		[RowNum] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [Relational].[SchemeUpliftTrans] ADD  CONSTRAINT [DF_Relational_SchemeUpliftTrans_ExcludeTime]  DEFAULT ((0)) FOR [ExcludeTime]

	ALTER TABLE [Relational].[SchemeUpliftTrans]  ADD  CONSTRAINT [FK_SchemeUpliftTrans_SchemeUpliftTransWeek] FOREIGN KEY([weekid])
	REFERENCES [Relational].[SchemeUpliftTrans_Week] ([ID])

	CREATE NONCLUSTERED INDEX [IX_Relational_SchemeUpliftTrans_Cover] ON [Relational].[SchemeUpliftTrans]
	(
		[AddedDate] ASC,
		[FanID] ASC,
		[PartnerID] ASC,
		[OutletID] ASC,
		[IsOnline] ASC,
		[weekid] ASC
	)
	INCLUDE ([Amount])

	ALTER INDEX IX_Relational_SchemeUpliftTrans_Cover ON Relational.SchemeUpliftTrans DISABLE

	CREATE NONCLUSTERED INDEX IX_Relational_SchemeUpliftTrans_MonthlyReportFacilitate
	ON [Relational].[SchemeUpliftTrans] ([IsRetailReport],[Amount])
	INCLUDE ([AddedDate],[FanID],[OutletID],[PartnerID],[IsOnline],[TranDate],[PaymentTypeID])

	ALTER INDEX IX_Relational_SchemeUpliftTrans_MonthlyReportFacilitate ON Relational.SchemeUpliftTrans DISABLE

	CREATE NONCLUSTERED INDEX IX_Relational_SchemeUpliftTrans_MemberSalesFacilitate
	ON [Relational].[SchemeUpliftTrans] ([PartnerID],[IsRetailReport],[Amount],[AddedDate])
	INCLUDE ([FanID],[OutletID],[IsOnline],[TranDate],[PaymentTypeID])

	ALTER INDEX IX_Relational_SchemeUpliftTrans_MemberSalesFacilitate ON Relational.SchemeUpliftTrans DISABLE

	TRUNCATE TABLE MI.SchemeUpliftTrans_Stage

	--IF @FileID = 0 --0 denotes reload of the whole table
	--BEGIN
	--	TRUNCATE TABLE Relational.SchemeUpliftTrans
	--END
    
END
