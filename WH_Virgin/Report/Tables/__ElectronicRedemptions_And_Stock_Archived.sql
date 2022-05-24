CREATE TABLE [Report].[__ElectronicRedemptions_And_Stock_Archived] (
    [ID]                              INT             IDENTITY (1, 1) NOT NULL,
    [ReportDate]                      DATE            NOT NULL,
    [WeekStart]                       DATE            NOT NULL,
    [WeekEnd]                         DATE            NOT NULL,
    [WeekID]                          INT             NOT NULL,
    [PartnerID]                       INT             NOT NULL,
    [RedemptionDescription]           NVARCHAR (4000) NOT NULL,
    [ItemID]                          INT             NOT NULL,
    [eVouchRedemptions]               INT             NULL,
    [eVouchRedemptionsMonthlyAverage] INT             NULL,
    [Current_eCodes_In_stock]         INT             NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

