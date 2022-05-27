CREATE TABLE [ExcelQuery].[WMTR_output] (
    [partnerID]      INT             NULL,
    [brandid]        INT             NULL,
    [brandname]      VARCHAR (255)   NULL,
    [partnername]    VARCHAR (255)   NULL,
    [reportdate]     DATE            NULL,
    [CY_sales]       DECIMAL (12, 2) NULL,
    [CY_sales_share] DECIMAL (4, 3)  NULL,
    [PY_sales]       DECIMAL (12, 2) NULL,
    [PY_sales_share] DECIMAL (4, 3)  NULL,
    [CY_txns]        INT             NULL,
    [CY_txn_share]   DECIMAL (4, 3)  NULL,
    [PY_txns]        INT             NULL,
    [PY_txn_share]   DECIMAL (4, 3)  NULL,
    [CY_custs]       INT             NULL,
    [CY_cust_share]  DECIMAL (4, 3)  NULL,
    [PY_custs]       INT             NULL,
    [PY_cust_share]  DECIMAL (4, 3)  NULL
);

