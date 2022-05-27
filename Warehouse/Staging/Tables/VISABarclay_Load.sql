CREATE TABLE [Staging].[VISABarclay_Load] (
    [fName]         VARCHAR (30)   NULL,
    [is_cnp]        VARCHAR (5)    NULL,
    [issuer_bin]    VARCHAR (10)   NULL,
    [mcc]           VARCHAR (4)    NULL,
    [mcg]           VARCHAR (10)   NULL,
    [merchant_id]   VARCHAR (50)   NULL,
    [merchant_name] VARCHAR (100)  NULL,
    [purchase_date] DATE           NULL,
    [n_first_seen]  INT            NULL,
    [n_seen]        INT            NULL,
    [pv_gbp]        DECIMAL (9, 2) NULL,
    [tx]            VARCHAR (5)    NULL
);


GO
CREATE CLUSTERED INDEX [cx_Stuff]
    ON [Staging].[VISABarclay_Load]([fName] ASC, [merchant_id] ASC) WITH (DATA_COMPRESSION = PAGE);

