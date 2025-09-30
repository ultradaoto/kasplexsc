'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';

interface IPNFT {
  tokenId: string;
  owner: string;
  cropSpecies: string;
  bacterialStrain: string;
  regulatoryStatus: string;
  licensedAcres: string;
  researchInstitution: string;
  approvalDate: string;
  metadataURI: string;
}

export default function IPNFTs() {
  const [ipnfts, setIpnfts] = useState<IPNFT[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchIPNFTs();
  }, []);

  const fetchIPNFTs = async () => {
    try {
      const response = await fetch('http://localhost:3000/api/ipnfts');
      const data = await response.json();
      
      if (data.error) {
        setError(data.error);
      } else {
        setIpnfts(data.tokens || []);
      }
    } catch (err) {
      setError('Failed to fetch IP-NFTs. Make sure contracts are deployed.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 via-white to-blue-50">
      <header className="bg-white shadow-sm border-b border-green-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <Link href="/" className="text-green-600 hover:text-green-700 text-sm mb-2 inline-block">
                ← Back to Dashboard
              </Link>
              <h1 className="text-3xl font-bold text-gray-900">
                Agricultural IP-NFT Collection
              </h1>
              <p className="mt-1 text-sm text-gray-600">
                Browse bacterial pesticide IP-NFTs on Kasplex Testnet
              </p>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="text-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600 mx-auto"></div>
              <p className="mt-4 text-gray-600">Loading IP-NFTs...</p>
            </div>
          </div>
        ) : error ? (
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6">
            <div className="flex items-center">
              <svg className="h-6 w-6 text-yellow-600 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
              <div>
                <h3 className="font-semibold text-yellow-900">No IP-NFTs Found</h3>
                <p className="text-yellow-700 mt-1">{error}</p>
                <p className="text-yellow-600 text-sm mt-2">
                  Deploy contracts first or mint some IP-NFTs to see them here.
                </p>
              </div>
            </div>
          </div>
        ) : ipnfts.length === 0 ? (
          <div className="bg-white border border-gray-200 rounded-lg p-12 text-center">
            <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
            </svg>
            <h3 className="mt-4 text-lg font-medium text-gray-900">No IP-NFTs minted yet</h3>
            <p className="mt-2 text-gray-600">Get started by minting your first agricultural IP-NFT.</p>
            <div className="mt-6">
              <Link
                href="/mint"
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700"
              >
                Mint IP-NFT
              </Link>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {ipnfts.map((nft) => (
              <div
                key={nft.tokenId}
                className="bg-white rounded-lg shadow-md overflow-hidden border border-gray-200 hover:shadow-lg transition-shadow"
              >
                <div className="bg-gradient-to-r from-green-500 to-blue-500 h-2"></div>
                <div className="p-6">
                  <div className="flex items-center justify-between mb-4">
                    <span className="text-2xl font-bold text-gray-900">
                      #{nft.tokenId}
                    </span>
                    <span className="px-3 py-1 bg-green-100 text-green-800 text-xs font-semibold rounded-full">
                      {nft.regulatoryStatus}
                    </span>
                  </div>

                  <h3 className="text-lg font-semibold text-gray-900 mb-2">
                    {nft.cropSpecies} IP
                  </h3>

                  <div className="space-y-2 text-sm">
                    <div>
                      <span className="text-gray-500">Bacterial Strain:</span>
                      <p className="text-gray-900 font-medium">{nft.bacterialStrain}</p>
                    </div>

                    <div>
                      <span className="text-gray-500">Institution:</span>
                      <p className="text-gray-900">{nft.researchInstitution}</p>
                    </div>

                    <div>
                      <span className="text-gray-500">Licensed Acres:</span>
                      <p className="text-gray-900 font-semibold">
                        {Number(nft.licensedAcres).toLocaleString()}
                      </p>
                    </div>

                    <div>
                      <span className="text-gray-500">Approval Date:</span>
                      <p className="text-gray-900">
                        {new Date(nft.approvalDate).toLocaleDateString()}
                      </p>
                    </div>
                  </div>

                  <div className="mt-4 pt-4 border-t border-gray-200">
                    <span className="text-xs text-gray-500">Owner:</span>
                    <p className="text-xs text-gray-700 font-mono truncate">
                      {nft.owner}
                    </p>
                  </div>

                  <div className="mt-4 flex space-x-2">
                    <Link
                      href={`/ipnfts/${nft.tokenId}`}
                      className="flex-1 text-center px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 text-sm font-medium"
                    >
                      View Details
                    </Link>
                    <Link
                      href={`/royalties/${nft.tokenId}`}
                      className="flex-1 text-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 text-sm font-medium"
                    >
                      Royalties
                    </Link>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
