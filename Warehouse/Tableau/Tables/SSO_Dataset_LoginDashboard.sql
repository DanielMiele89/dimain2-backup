CREATE TABLE [Tableau].[SSO_Dataset_LoginDashboard] (
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
    [PostcodeDistrict]             VARCHAR (7)   NULL,
    CONSTRAINT [PK_SSO_Dataset_LoginDashboard] PRIMARY KEY CLUSTERED ([SSO_Dataset_LoginDashboardID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [idx_SSO_Dataset_LoginDashboard]
    ON [Tableau].[SSO_Dataset_LoginDashboard]([CustomerID] ASC, [ActionType] ASC, [ActionDateTime] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

