CREATE TABLE [dbo].[MSSQL_DroppedLedgerTable_Hierarchy1_35211AEF5DFA49949A885F8A0E51A52E] (
    [Hierarchy1_ID]                INT           IDENTITY (1, 1) NOT NULL,
    [Hierarchy1_Code]              VARCHAR (255) NULL,
    [Hierarchy1_Name]              VARCHAR (255) NULL,
    [ledger_start_transaction_id]  BIGINT        NOT NULL,
    [ledger_end_transaction_id]    BIGINT        NULL,
    [ledger_start_sequence_number] BIGINT        NOT NULL,
    [ledger_end_sequence_number]   BIGINT        NULL
);
GO

