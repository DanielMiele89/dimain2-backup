CREATE TABLE [Staging].[Inbound_Balances_FullRefresh] (
    [cleared]          INT           NOT NULL,
    [rewardCustomerID] NVARCHAR (50) NOT NULL,
    [lifetime]         INT           NOT NULL,
    [pending]          FLOAT (53)    NOT NULL
);

