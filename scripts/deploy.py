from brownie import accounts, PProxy, wLSPair
from brownie.network import priority_fee

LS_PAIR = '0x79b6BD0FC723746bC9eAEFeF34613cF4596E6dEF'
TIMELOCK = '0x6Bd0D8c8aD8D3F1f97810d5Cc57E9296db73DC45'
SAFE_ADDRESS = '0x6458A23B020f489651f2777Bd849ddEd34DfCcd2'

def setup():
    priority_fee('auto')

def main():
    # need to create 'piedao-deployer' account to be able to deploy
    setup()

    account = accounts.load('piedao-deployer') 
    pproxy = PProxy.deploy({'from': account})
    wls_impl = wLSPair.deploy({'from': account})
    
    pproxy.setImplementation(wls_impl.address, {'from': account})

    data = wls_impl.initialize.encode_input(LS_PAIR, TIMELOCK)
    account.transfer(pproxy.address, data=data)

    pproxy.setProxyOwner(SAFE_ADDRESS, {'from': account})

    data = wls_impl.transferOwnership.encode_input(SAFE_ADDRESS)
    account.transfer(pproxy.address, data=data)