import { Body, Controller, Get, Param, ParseIntPipe, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { BlockchainService } from './blockchain.service.js';
import type { ReviewData } from './blockchain.service.js';

@ApiTags('blockchain')
@Controller()
export class BlockchainController {
  constructor(private readonly blockchainService: BlockchainService) {}

  @Post('hash')
  @Post('hash-chain')
  async hash(@Body() data: ReviewData) {
    const hash = await this.blockchainService.hashReviewWithPrevious({
      ...data,
      previousHash: (data as ReviewData & { previousHash?: string }).previousHash ?? '',
    });

    const ledger = this.blockchainService.getLedger();
    const entry = ledger[ledger.length - 1];

    return {
      success: true,
      hash,
      previousHash: entry?.previousHash,
      timestamp: entry?.timestamp,
    };
  }

  @Get('verify/:reviewId/:hash')
  async verify(
    @Param('reviewId', ParseIntPipe) reviewId: number,
    @Param('hash') hash: string,
  ) {
    const isValid = await this.blockchainService.verifyReview(reviewId, hash);
    return { reviewId, isValid };
  }

  @Get('ledger')
  getLedger() {
    return this.blockchainService.getLedger();
  }

  @Get('health')
  health() {
    return this.blockchainService.getHealth();
  }
}