CREATE TABLE [ExcelQuery].[STOSales_BespokeCustomers] (
    [fANID]          INT           NOT NULL,
    [CINID]          INT           NOT NULL,
    [Gender]         CHAR (1)      NULL,
    [Age_Group]      VARCHAR (12)  NULL,
    [CAMEO_CODE_GRP] VARCHAR (151) NOT NULL,
    [Region]         VARCHAR (30)  NULL,
    [ComboID_2]      BIGINT        NULL,
    [Index_RR]       REAL          NULL
);


GO
CREATE NONCLUSTERED INDEX [IND_Cins]
    ON [ExcelQuery].[STOSales_BespokeCustomers]([CINID] ASC);

