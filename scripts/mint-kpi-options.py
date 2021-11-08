from brownie import accounts, interface, wLSPair
from brownie.network import priority_fee
from ape_safe import ApeSafe
from decimal import Decimal

LS_PAIR = '0x79b6BD0FC723746bC9eAEFeF34613cF4596E6dEF'
SAFE_ADDRESS = '0x6458A23B020f489651f2777Bd849ddEd34DfCcd2'
DOUGH_ADDRESS = '0xad32A8e6220741182940c5aBF610bDE99E737b2D'

KPI_TO_MINT = Decimal(10_000_000) * Decimal(1e18)

def main():
    safe = ApeSafe(SAFE_ADDRESS)
    ls_pair = interface.ILSPair(LS_PAIR, owner=safe.account)
    dough = interface.ERC20(DOUGH_ADDRESS, owner=safe.account)
    long_token = interface.ERC20(ls_pair.longToken(), owner=safe.account)
    collateral_per_pair = Decimal(ls_pair.collateralPerPair())
    dough.approve(LS_PAIR, int(collateral_per_pair * KPI_TO_MINT))
    ls_pair.create(10_000 * 1e18)


    safe_tx = safe.multisend_from_receipts()
    safe.preview(safe_tx)
    
    print(f'The Safe owns {long_token.balanceOf(SAFE_ADDRESS)} {long_token.symbol()} after minting')

    safe.post_transaction(safe_tx)
