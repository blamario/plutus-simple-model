-- | Utility functions for Plutus V1 scripts
module Plutus.Model.Validator.V1.Plutus(
  getThrough,
  datumOf,
) where

import PlutusTx.Prelude
import Plutus.V1.Ledger.Api
import Plutus.V1.Ledger.Contexts

{-# inlinable getThrough #-}
getThrough :: ScriptContext -> (TxOut, TxOut)
getThrough ctx = (tin, tout)
  where
    [tout] = getContinuingOutputs ctx
    Just tinInfo = findOwnInput ctx
    tin = txInInfoResolved tinInfo

{-# inlinable datumOf #-}
datumOf :: FromData a => TxInfo -> TxOut -> Maybe a
datumOf info tout = do
  dh <- txOutDatumHash tout
  dat <- getDatum <$> findDatum dh info
  fromBuiltinData dat

