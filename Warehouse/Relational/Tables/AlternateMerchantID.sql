CREATE TABLE [Relational].[AlternateMerchantID] (
    [ID]                  INT           IDENTITY (1, 1) NOT NULL,
    [MerchantID]          VARCHAR (50)  NULL,
    [AlternateMerchantID] VARCHAR (50)  NULL,
    [MerchantComment]     VARCHAR (100) NULL
);

