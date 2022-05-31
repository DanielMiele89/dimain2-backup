CREATE TABLE [Vernon].[nowtv_omni_migration] (
    [cinid]                    INT          NOT NULL,
    [first_trans_date]         DATE         NULL,
    [last_trans_date]          DATE         NULL,
    [BrandName]                VARCHAR (50) NOT NULL,
    [spend]                    MONEY        NULL,
    [transactions]             INT          NULL,
    [Current_customer_nowtv]   INT          NOT NULL,
    [Current_customer_netflix] INT          NOT NULL
);

