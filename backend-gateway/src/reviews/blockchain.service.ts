import { Injectable } from '@nestjs/common';
import * as crypto from 'crypto';

export interface ReviewData {
  reviewId: number;
  jobId: number;
  reviewerId: number;
  revieweeId: number;
  overallRating: number;
  comment: string;
  imageUrls: string[];
  createdAt: string;
}

export interface LedgerEntry {
  reviewId: number;
  hash: string;
  previousHash: string;
  timestamp: string;
}

const ledger: LedgerEntry[] = [];

@Injectable()
export class BlockchainService {
  private readonly genesisHash = '0000000000000000';

  private generateHash(data: ReviewData, previousHash: string): string {
    const content = JSON.stringify({
      reviewId: data.reviewId,
      jobId: data.jobId,
      reviewerId: data.reviewerId,
      revieweeId: data.revieweeId,
      overallRating: data.overallRating,
      comment: data.comment,
      imageUrls: data.imageUrls,
      createdAt: data.createdAt,
      previousHash,
    });

    return crypto.createHash('sha256').update(content).digest('hex');
  }

  private getPreviousHash(): string {
    return ledger.length > 0 ? ledger[ledger.length - 1].hash : this.genesisHash;
  }

  private addToLedger(data: ReviewData, previousHash?: string): LedgerEntry {
    const effectivePreviousHash = previousHash?.trim() || this.getPreviousHash();
    const hash = this.generateHash(data, effectivePreviousHash);

    const entry: LedgerEntry = {
      reviewId: data.reviewId,
      hash,
      previousHash: effectivePreviousHash,
      timestamp: new Date().toISOString(),
    };

    ledger.push(entry);
    return entry;
  }

  // 🔗 FULL BLOCKCHAIN: Hash with previous hash
  async hashReviewWithPrevious(data: ReviewData & { previousHash: string }): Promise<string> {
    try {
      const entry = this.addToLedger(data, data.previousHash);
      return entry.hash;
    } catch (error) {
      console.error('Blockchain hash error:', error);
      const fallbackData = JSON.stringify({
        ...data,
        timestamp: Date.now(),
      });
      return crypto.createHash('sha256').update(fallbackData).digest('hex');
    }
  }

  async verifyReview(reviewId: number, hash: string): Promise<boolean> {
    const entry = ledger.find((e) => e.reviewId === reviewId);
    if (!entry) return false;
    return entry.hash === hash;
  }

  getLedger(): LedgerEntry[] {
    return ledger;
  }

  getHealth(): { status: string } {
    return { status: 'ok' };
  }
}