CREATE TABLE [Staging].[SSRS_R0097_HalfordsWeeklyReport] (
    [PartnerName]        NVARCHAR (100) NOT NULL,
    [ParterID]           INT            NOT NULL,
    [Years]              INT            NULL,
    [Week_No]            INT            NULL,
    [Trans_Amount]       MONEY          NULL,
    [Commission_exclVAT] MONEY          NULL,
    [Cashback]           MONEY          NULL,
    [No_Trans]           INT            NULL,
    [No_Spenders]        INT            NULL,
    [First_Tran]         DATE           NULL,
    [Last_Tran]          DATE           NULL,
    [Start_Date]         DATE           NULL,
    [End_Date]           DATE           NULL
);

