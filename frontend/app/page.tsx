'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';

interface NetworkInfo {
  chainId: string;
  blockNumber: number;
  rpcUrl: string;
  name: string;
}

interface ContractAddresses {
  ipnft: string | null;
  royaltyDistributor: string | null;
  tokenizer: string | null;
}

export default function Home() {
  const [networkInfo, setNetworkInfo] = useState<NetworkInfo | null>(null);
  const [contracts, setContracts] = useState<ContractAddresses | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const [networkRes, contractsRes] = await Promise.all([
        fetch('http://localhost:3000/api/network'),
        fetch('http://localhost:3000/api/contracts')
      ]);

      const networkData = await networkRes.json();
      const contractsData = await contractsRes.json();

      setNetworkInfo(networkData);
      setContracts(contractsData);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 via-white to-blue-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-green-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                🌾 Agricultural IP Tokenization
              </h1>
              <p className="mt-1 text-sm text-gray-600">
                Kasplex Testnet - Bacterial Pesticide IP-NFTs
              </p>
            </div>
            <div className="flex items-center space-x-4">
              {networkInfo && (
                <div className="text-right">
                  <div className="text-xs text-gray-500">Network</div>
                  <div className="text-sm font-medium text-green-600">
                    {networkInfo.name}
                  </div>
                  <div className="text-xs text-gray-500">
                    Block: {networkInfo.blockNumber.toLocaleString()}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="text-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600 mx-auto"></div>
              <p className="mt-4 text-gray-600">Loading...</p>
            </div>
          </div>
        ) : (
          <>
            {/* Quick Stats */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
              <div className="bg-white rounded-lg shadow-md p-6 border border-green-100">
                <div className="flex items-center">
                  <div className="flex-shrink-0 bg-green-100 rounded-md p-3">
                    <svg className="h-6 w-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <div className="ml-4">
                    <div className="text-sm font-medium text-gray-500">Network Status</div>
                    <div className="text-2xl font-bold text-gray-900">Active</div>
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-lg shadow-md p-6 border border-blue-100">
                <div className="flex items-center">
                  <div className="flex-shrink-0 bg-blue-100 rounded-md p-3">
                    <svg className="h-6 w-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                    </svg>
                  </div>
                  <div className="ml-4">
                    <div className="text-sm font-medium text-gray-500">Contracts</div>
                    <div className="text-2xl font-bold text-gray-900">
                      {contracts?.ipnft ? 'Deployed' : 'Not Deployed'}
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-lg shadow-md p-6 border border-purple-100">
                <div className="flex items-center">
                  <div className="flex-shrink-0 bg-purple-100 rounded-md p-3">
                    <svg className="h-6 w-6 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <div className="ml-4">
                    <div className="text-sm font-medium text-gray-500">Chain ID</div>
                    <div className="text-2xl font-bold text-gray-900">
                      {networkInfo?.chainId || '-'}
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Main Actions */}
            <div className="bg-white rounded-lg shadow-lg p-8 mb-8">
              <h2 className="text-2xl font-bold text-gray-900 mb-6">
                Get Started
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <Link
                  href="/ipnfts"
                  className="block p-6 bg-gradient-to-br from-green-50 to-green-100 rounded-lg hover:shadow-md transition-shadow border border-green-200"
                >
                  <div className="flex items-center mb-3">
                    <div className="bg-green-600 text-white rounded-lg p-2">
                      <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                      </svg>
                    </div>
                    <h3 className="ml-3 text-lg font-semibold text-gray-900">
                      Browse IP-NFTs
                    </h3>
                  </div>
                  <p className="text-gray-600">
                    Explore agricultural biotech IP-NFTs representing bacterial pesticide alternatives
                  </p>
                </Link>

                <Link
                  href="/deploy"
                  className="block p-6 bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg hover:shadow-md transition-shadow border border-blue-200"
                >
                  <div className="flex items-center mb-3">
                    <div className="bg-blue-600 text-white rounded-lg p-2">
                      <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                      </svg>
                    </div>
                    <h3 className="ml-3 text-lg font-semibold text-gray-900">
                      Deploy Contracts
                    </h3>
                  </div>
                  <p className="text-gray-600">
                    Deploy the IP tokenization system to Kasplex testnet
                  </p>
                </Link>

                <Link
                  href="/mint"
                  className="block p-6 bg-gradient-to-br from-purple-50 to-purple-100 rounded-lg hover:shadow-md transition-shadow border border-purple-200"
                >
                  <div className="flex items-center mb-3">
                    <div className="bg-purple-600 text-white rounded-lg p-2">
                      <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                      </svg>
                    </div>
                    <h3 className="ml-3 text-lg font-semibold text-gray-900">
                      Mint IP-NFT
                    </h3>
                  </div>
                  <p className="text-gray-600">
                    Create a new IP-NFT for your agricultural biotech innovation
                  </p>
                </Link>

                <Link
                  href="/royalties"
                  className="block p-6 bg-gradient-to-br from-orange-50 to-orange-100 rounded-lg hover:shadow-md transition-shadow border border-orange-200"
                >
                  <div className="flex items-center mb-3">
                    <div className="bg-orange-600 text-white rounded-lg p-2">
                      <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    </div>
                    <h3 className="ml-3 text-lg font-semibold text-gray-900">
                      Manage Royalties
                    </h3>
                  </div>
                  <p className="text-gray-600">
                    View and manage royalty distributions for IP-NFT holders
                  </p>
                </Link>
              </div>
            </div>

            {/* Contract Status */}
            {contracts && (
              <div className="bg-white rounded-lg shadow-md p-6">
                <h2 className="text-xl font-bold text-gray-900 mb-4">
                  Contract Addresses
                </h2>
                <div className="space-y-3">
                  <div className="flex items-center justify-between p-3 bg-gray-50 rounded">
                    <span className="font-medium text-gray-700">IP-NFT Contract:</span>
                    <span className="text-sm text-gray-600 font-mono">
                      {contracts.ipnft || 'Not deployed'}
                    </span>
                  </div>
                  <div className="flex items-center justify-between p-3 bg-gray-50 rounded">
                    <span className="font-medium text-gray-700">Royalty Distributor:</span>
                    <span className="text-sm text-gray-600 font-mono">
                      {contracts.royaltyDistributor || 'Not deployed'}
                    </span>
                  </div>
                  <div className="flex items-center justify-between p-3 bg-gray-50 rounded">
                    <span className="font-medium text-gray-700">IP Tokenizer:</span>
                    <span className="text-sm text-gray-600 font-mono">
                      {contracts.tokenizer || 'Not deployed'}
                    </span>
                  </div>
                </div>
              </div>
            )}
          </>
        )}
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-200 mt-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="text-center text-sm text-gray-500">
            <p>Agricultural IP Tokenization System - Kasplex Testnet</p>
            <p className="mt-1">
              Built with Foundry, Next.js, and Express (MVC)
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}