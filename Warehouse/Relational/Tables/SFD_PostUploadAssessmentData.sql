CREATE TABLE [Relational].[SFD_PostUploadAssessmentData] (
    [CampaignKey]       VARCHAR (7)     NOT NULL,
    [AgreedTCsDate]     DATETIME        NULL,
    [ClubCashAvailable] NUMERIC (32, 2) NULL,
    [ClubCashPending]   NUMERIC (32, 2) NULL,
    [ClubID]            INT             NULL,
    [Customer ID]       INT             NOT NULL,
    [Email]             VARCHAR (150)   NULL,
    [Email Permission]  VARCHAR (1)     NULL,
    [Firstname]         VARCHAR (50)    NULL,
    [Last Loaded Date]  DATETIME        NULL,
    [Lastname]          VARCHAR (50)    NULL,
    [LionSendID]        SMALLINT        NULL,
    [Offer1]            INT             NULL,
    [Offer2]            INT             NULL,
    [Offer3]            INT             NULL,
    [Offer4]            INT             NULL,
    [Offer5]            INT             NULL,
    [Offer6]            INT             NULL,
    [Offer7]            INT             NULL,
    [Partial Postcode]  VARCHAR (5)     NULL,
    [POCCustomer]       INT             NULL,
    [Preferred Format]  INT             NULL,
    [CJS]               VARCHAR (3)     NULL,
    [WeekNumber]        TINYINT         NULL,
    CONSTRAINT [pk_CampKey_FanID] PRIMARY KEY CLUSTERED ([CampaignKey] ASC, [Customer ID] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IDX_LSID]
    ON [Relational].[SFD_PostUploadAssessmentData]([LionSendID] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE);


GO
DENY SELECT
    ON OBJECT::[Relational].[SFD_PostUploadAssessmentData] TO [New_PIIRemoved]
    AS [dbo];

