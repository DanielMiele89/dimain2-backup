CREATE TABLE [Stratification].[ShareOfWallet_AR005] (
    [MonthID]              INT              NOT NULL,
    [PartnerID]            INT              NOT NULL,
    [BrandName]            VARCHAR (50)     NOT NULL,
    [isPartner]            INT              NOT NULL,
    [TY_Share_of_Wallet_A] NUMERIC (38, 17) NULL,
    [LY_Share_of_Wallet_A] NUMERIC (38, 17) NULL,
    [TY_Sector_Spend_A]    MONEY            NULL,
    [LY_Sector_Spend_A]    MONEY            NULL,
    [TY_Share_of_Wallet_C] NUMERIC (38, 17) NULL,
    [LY_Share_of_Wallet_C] NUMERIC (38, 17) NULL,
    [TY_Sector_Spend_C]    MONEY            NULL,
    [LY_Sector_Spend_C]    MONEY            NULL
);

