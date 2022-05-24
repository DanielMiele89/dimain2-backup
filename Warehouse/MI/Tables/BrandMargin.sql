CREATE TABLE [MI].[BrandMargin] (
    [BrandID]    SMALLINT       NOT NULL,
    [Margin]     DECIMAL (6, 4) NOT NULL,
    [Inserted]   SMALLDATETIME  NULL,
    [InsertedBy] NVARCHAR (128) NULL,
    [Updated]    SMALLDATETIME  NULL,
    [UpdatedBy]  NVARCHAR (128) NULL,
    PRIMARY KEY CLUSTERED ([BrandID] ASC),
    CHECK ([Margin]>=(0) AND [Margin]<=(1))
);


GO
CREATE TRIGGER [MI].TrgAfterInsert3 ON warehouse.MI.BrandMargin
AFTER INSERT
AS
    UPDATE warehouse.MI.BrandMargin
    SET Updated = GETDATE(), UpdatedBy=SYSTEM_USER,Inserted = GETDATE(), InsertedBy=SYSTEM_USER
    WHERE BrandID IN (SELECT DISTINCT BrandID FROM Inserted)
GO
CREATE TRIGGER [MI].TrgAfterUpdate3 ON warehouse.MI.BrandMargin
AFTER UPDATE
AS
    UPDATE warehouse.MI.BrandMargin
    SET Updated = GETDATE(), UpdatedBy=SYSTEM_USER
    WHERE BrandID IN (SELECT DISTINCT BrandID FROM Inserted)