CREATE TABLE [Vernon].[nowtv_ALLCUSTOMER_DATA] (
    [cinid]                    INT          NOT NULL,
    [first_trans_date]         DATE         NULL,
    [last_trans_date]          DATE         NULL,
    [BrandName]                VARCHAR (50) NOT NULL,
    [spend]                    MONEY        NULL,
    [transactions]             INT          NULL,
    [Current_customer_nowtv]   INT          NULL,
    [Current_customer_netflix] INT          NULL,
    [Omni_customer]            INT          NOT NULL
);

