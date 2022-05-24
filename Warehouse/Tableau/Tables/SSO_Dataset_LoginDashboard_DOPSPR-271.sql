CREATE TABLE [Tableau].[SSO_Dataset_LoginDashboard_DOPSPR-271] (
    [SSO_Dataset_LoginDashboardID] INT           IDENTITY (1, 1) NOT NULL,
    [CustomerID]                   INT           NOT NULL,
    [ActionDateTime]               DATETIME      NULL,
    [ActionType]                   VARCHAR (20)  NULL,
    [LoginType]                    VARCHAR (7)   NULL,
    [CustomerStatus]               VARCHAR (18)  NULL,
    [SessionLength]                INT           NULL,
    [DeviceBrand]                  NVARCHAR (50) NULL,
    [DeviceType]                   NVARCHAR (50) NULL,
    [DeviceModel]                  NVARCHAR (50) NULL,
    [AccountType]                  VARCHAR (7)   NULL,
    [Bank]                         VARCHAR (7)   NULL,
    [Region]                       VARCHAR (30)  NULL,
    [PostcodeDistrict]             VARCHAR (7)   NULL
);

