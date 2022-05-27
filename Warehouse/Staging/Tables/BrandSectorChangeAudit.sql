CREATE TABLE [Staging].[BrandSectorChangeAudit] (
    [ChangeAuditID]    INT            IDENTITY (1, 1) NOT NULL,
    [BrandID]          SMALLINT       NOT NULL,
    [PreviousSectorID] TINYINT        NULL,
    [NewSectorID]      TINYINT        NOT NULL,
    [AuditDate]        DATE           DEFAULT (getdate()) NOT NULL,
    [Notes]            VARCHAR (8000) DEFAULT ('') NOT NULL,
    PRIMARY KEY CLUSTERED ([ChangeAuditID] ASC)
);

