CREATE TABLE [Staging].[SFD_EmailExports_OLD] (
    [ID]                    INT            IDENTITY (1, 1) NOT NULL,
    [AgreedTcsDate]         DATETIME       NULL,
    [ClubCashAvailable]     FLOAT (53)     NULL,
    [ClubCashPending]       FLOAT (53)     NULL,
    [ClubID]                FLOAT (53)     NULL,
    [customer id]           FLOAT (53)     NULL,
    [CustomerJourneyStatus] NVARCHAR (255) NULL,
    [Email]                 NVARCHAR (255) NULL,
    [Email Permission]      FLOAT (53)     NULL,
    [MOT1-week]             FLOAT (53)     NULL,
    [MOT2-week]             FLOAT (53)     NULL,
    [MOT3-week]             NVARCHAR (255) NULL,
    [POCcustomer]           NVARCHAR (255) NULL,
    [EmailDate]             DATE           NOT NULL,
    [EmailType]             CHAR (1)       NOT NULL
);

