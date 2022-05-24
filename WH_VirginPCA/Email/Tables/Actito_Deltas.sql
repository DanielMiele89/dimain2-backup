CREATE TABLE [Email].[Actito_Deltas] (
    [FanID]                   INT            NOT NULL,
    [Email]                   NVARCHAR (255) NULL,
    [PublisherID]             INT            NULL,
    [CustomerSegment]         NVARCHAR (24)  NULL,
    [Title]                   NVARCHAR (24)  NULL,
    [FirstName]               NVARCHAR (64)  NULL,
    [LastName]                NVARCHAR (64)  NULL,
    [DOB]                     DATE           NULL,
    [CashbackAvailable]       NVARCHAR (24)  NULL,
    [CashbackPending]         NVARCHAR (24)  NULL,
    [CashbackLTV]             NVARCHAR (24)  NULL,
    [PartialPostCode]         NVARCHAR (5)   NULL,
    [Marketable]              BIT            NULL,
    [EmailTracking]           BIT            NULL,
    [Birthday_Flag]           BIT            NULL,
    [Birthday_Code]           NVARCHAR (255) NULL,
    [Birthday_CodeExpiryDate] DATE           NULL,
    [FirstEarn_Date]          DATE           NULL,
    [FirstEarn_Amount]        NVARCHAR (24)  NULL,
    [FirstEarn_RetailerName]  NVARCHAR (255) NULL,
    [FirstEarn_Type]          NVARCHAR (255) NULL,
    [Reached5GBP_Date]        DATE           NULL,
    [RedeemReminder_Amount]   NVARCHAR (24)  NULL,
    [RedeemReminder_Day]      INT            NULL,
    [EarnConfirmation_Date]   DATE           NULL,
    [CustomField1]            NVARCHAR (255) NULL,
    [CustomField2]            NVARCHAR (255) NULL,
    [CustomField3]            NVARCHAR (255) NULL,
    [CustomField4]            NVARCHAR (255) NULL,
    [CustomField5]            NVARCHAR (255) NULL,
    [CustomField6]            NVARCHAR (255) NULL,
    [CustomField7]            NVARCHAR (255) NULL,
    [CustomField8]            NVARCHAR (255) NULL,
    [CustomField9]            NVARCHAR (255) NULL,
    [CustomField10]           NVARCHAR (255) NULL,
    [CustomField11]           INT            NULL,
    [CustomField12]           DATE           NULL,
    CONSTRAINT [PK_Actito_Deltas] PRIMARY KEY CLUSTERED ([FanID] ASC)
);




GO
DENY SELECT
    ON OBJECT::[Email].[Actito_Deltas] TO [New_Insight]
    AS [New_DataOps];

