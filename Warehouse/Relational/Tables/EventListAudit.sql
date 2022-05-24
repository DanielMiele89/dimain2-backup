CREATE TABLE [Relational].[EventListAudit] (
    [EventListAuditID] INT            IDENTITY (1, 1) NOT NULL,
    [EventListID]      INT            NOT NULL,
    [BrandID]          SMALLINT       NULL,
    [EventTypeID]      TINYINT        NOT NULL,
    [StartDate]        DATE           NOT NULL,
    [EndDate]          DATE           NOT NULL,
    [IsTentative]      BIT            DEFAULT ((0)) NOT NULL,
    [Notes]            VARCHAR (8000) NULL,
    [AuditAction]      VARCHAR (50)   NULL,
    [AuditDate]        SMALLDATETIME  DEFAULT (getdate()) NULL,
    [EventTitle]       VARCHAR (60)   NOT NULL,
    PRIMARY KEY CLUSTERED ([EventListAuditID] ASC)
);

