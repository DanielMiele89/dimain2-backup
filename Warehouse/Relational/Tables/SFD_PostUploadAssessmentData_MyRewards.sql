CREATE TABLE [Relational].[SFD_PostUploadAssessmentData_MyRewards] (
    [CampaignKey]       VARCHAR (7)     NOT NULL,
    [AgreedTcsDate]     DATETIME        NULL,
    [ClubCashAvailable] NUMERIC (32, 2) NULL,
    [ClubCashPending]   NUMERIC (32, 2) NULL,
    [ClubID]            SMALLINT        NULL,
    [Customer ID]       INT             NOT NULL,
    [Email]             VARCHAR (150)   NULL,
    [IsCredit]          BIT             NULL,
    [IsDebit]           BIT             NULL,
    [IsLoyalty]         BIT             NULL,
    [LionSendID]        SMALLINT        NULL,
    [LoyaltyAccount]    BIT             NULL,
    [Nominee]           BIT             NULL,
    [Offer1]            SMALLINT        NULL,
    [Offer2]            SMALLINT        NULL,
    [Offer3]            SMALLINT        NULL,
    [Offer4]            SMALLINT        NULL,
    [Offer5]            SMALLINT        NULL,
    [Offer6]            SMALLINT        NULL,
    [Offer7]            SMALLINT        NULL,
    [OnTrial]           BIT             NULL,
    [Reached5GBP]       DATE            NULL,
    [WG]                BIT             NULL,
    [InsertDate]        DATE            NULL,
    CONSTRAINT [pk_CpKey_FanID] PRIMARY KEY CLUSTERED ([CampaignKey] ASC, [Customer ID] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IDX_LSID]
    ON [Relational].[SFD_PostUploadAssessmentData_MyRewards]([LionSendID] ASC);


GO
DENY SELECT
    ON OBJECT::[Relational].[SFD_PostUploadAssessmentData_MyRewards] TO [New_PIIRemoved]
    AS [dbo];

