const Cash = artifacts.require('Cash');

function toBN(x) {
    return '0x' + (Math.floor(x * (10 ** 18))).toString(16);
}

function toBN2(x) {
    return Math.floor(x * (10 ** 18));
}

contract('Cash', ([alice, bob, carol]) => {

    beforeEach(async () => {
        this.cash = await Cash.new({ from: alice });
        await this.cash.setMinter(alice, true);
        await this.cash.setFeeSetter(alice, true);
        await this.cash.setFeeFreeSender(bob, true);
        await this.cash.setFeeFreeReceiver(carol, true);
        await this.cash.setFee(500000);
        await this.cash.setMintBalance(toBN(20000000));
    });

    /*it('test swap', async () => {
        console.log(await this.pair.getReserves())
        await this.exp.swap(this.factory.address, this.dai.address, this.bac.address, toBN(1000));
        console.log(await this.pair.getReserves())
        
    });*/

    it('test exp price', async () => {

        await this.cash.mint(alice, toBN(1000));
        assert.equal(await this.cash.balanceOf(alice), toBN2(1000));
        await this.cash.transfer(bob, toBN(200), {from: alice});
        assert.equal(await this.cash.balanceOf(alice), toBN2(800));
        assert.equal(await this.cash.balanceOf(bob), toBN2(100));

        await this.cash.transfer(alice, toBN(50), {from: bob});
        assert.equal(await this.cash.balanceOf(alice), toBN2(850));
        assert.equal(await this.cash.balanceOf(bob), toBN2(50));

        await this.cash.transfer(carol, toBN(100), {from: alice});
        assert.equal(await this.cash.balanceOf(alice), toBN2(750));
        assert.equal(await this.cash.balanceOf(carol), toBN2(100));
        assert.equal(await this.cash.feeFreeReceiversCount(), 1);

        await this.cash.setFeeFreeReceiver(carol, false);
        await this.cash.transfer(carol, toBN(100), {from: alice});
        assert.equal(await this.cash.balanceOf(alice), toBN2(650));
        assert.equal(await this.cash.balanceOf(carol), toBN2(150));
        assert.equal(await this.cash.feeFreeReceiversCount(), 0);

        
    });
    
  });
