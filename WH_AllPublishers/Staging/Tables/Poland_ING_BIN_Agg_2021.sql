CREATE TABLE [Staging].[Poland_ING_BIN_Agg_2021] (
    [cpd]           DATETIME      NULL,
    [is_cnp]        BIT           NULL,
    [issuer_bin]    INT           NULL,
    [mcc]           INT           NULL,
    [mcg]           INT           NULL,
    [merchant_id]   INT           NULL,
    [merchant_name] VARCHAR (400) NULL,
    [n_first_seen]  INT           NULL,
    [n_seen]        INT           NULL,
    [pv_pln]        REAL          NULL,
    [tx]            INT           NULL,
    [cpd_ym]        INT           NULL
);

