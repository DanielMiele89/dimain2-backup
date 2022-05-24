CREATE TABLE [WHB].[Inbound_CustomerExternalIds] (
    [CustomerExternalLinkID] BIGINT           NOT NULL,
    [CustomerGUID]           UNIQUEIDENTIFIER NOT NULL,
    [ExternalID]             NVARCHAR (255)   NOT NULL,
    [ExternalIDSource]       NVARCHAR (255)   NOT NULL,
    [ActiveFrom]             DATETIME2 (7)    NOT NULL,
    [ActiveTo]               DATETIME2 (7)    NULL,
    [IsPrimary]              BIT              NOT NULL,
    [ClosurePending]         DATETIME2 (7)    NULL,
    [LoadDate]               DATETIME2 (7)    NOT NULL,
    [FileName]               NVARCHAR (320)   NOT NULL,
    PRIMARY KEY CLUSTERED ([CustomerExternalLinkID] ASC)
);

