/**
 * MathTuro LMS — Quiz Item Analysis & Psychometric Analytics Engine
 * Batch 4: Item Difficulty Index (p), Discrimination Index (D), Distractor Analysis, and Most Missed Items
 */

(function (window) {
    'use strict';

    function computeItemAnalysis(questions, attempts, answers, isAssessment) {
        if (!questions || questions.length === 0) {
            return { isEmpty: true, message: 'This questionnaire has no questions configured.' };
        }

        if (!attempts || attempts.length === 0) {
            return { isEmpty: true, message: 'No student attempts have been submitted for this test yet.' };
        }

        if (!answers || answers.length === 0) {
            return {
                isEmpty: true,
                message: 'No itemized student responses found. (Submissions may have been recorded through external form links rather than the native test runner).'
            };
        }

        // 1. Calculate overall cohort statistics
        const totalAttemptsCount = attempts.length;
        const scoreKey = isAssessment ? 'score' : 'student_score';
        const totalItemsKey = 'total_items';

        const totalScores = attempts.map(a => Number(a[scoreKey]) || 0);
        const sumScores = totalScores.reduce((acc, s) => acc + s, 0);
        const avgScore = totalAttemptsCount > 0 ? (sumScores / totalAttemptsCount).toFixed(1) : 0;

        // Passing threshold: 75% for post-test, or custom passing_score
        let passedAttempts = 0;
        attempts.forEach(a => {
            if (isAssessment) {
                if (a.assessment_result === 'passed' || (a.percentage && a.percentage >= 75)) passedAttempts++;
            } else {
                const total = a[totalItemsKey] || 1;
                const pct = (Number(a[scoreKey]) / total) * 100;
                if (pct >= 75) passedAttempts++;
            }
        });
        const passingRate = totalAttemptsCount > 0 ? Math.round((passedAttempts / totalAttemptsCount) * 100) : 0;

        // 2. Sort attempts descending by score to identify Upper 27% and Lower 27% cohorts
        const sortedAttempts = [...attempts].sort((a, b) => (Number(b[scoreKey]) || 0) - (Number(a[scoreKey]) || 0));
        const cohortSize = Math.max(1, Math.round(totalAttemptsCount * 0.27));
        const canComputeDiscrimination = totalAttemptsCount >= 4;

        const upperCohortIds = new Set(sortedAttempts.slice(0, cohortSize).map(a => String(a.id)));
        const lowerCohortIds = new Set(sortedAttempts.slice(-cohortSize).map(a => String(a.id)));

        // Index answers by question_id
        const answersByQuestion = {};
        answers.forEach(ans => {
            const qId = String(ans.question_id);
            if (!answersByQuestion[qId]) answersByQuestion[qId] = [];
            answersByQuestion[qId].push(ans);
        });

        // 3. Process each question
        const items = questions.map((q, idx) => {
            const qId = String(q.id);
            const qAnswers = answersByQuestion[qId] || [];
            const attemptCount = qAnswers.length;

            let correctCount = 0;
            let upperCorrectCount = 0;
            let lowerCorrectCount = 0;
            const optionCounts = {};

            qAnswers.forEach(ans => {
                if (ans.is_correct) correctCount++;

                const attemptId = String(ans.assessment_attempt_id || ans.quiz_submission_id || '');
                if (canComputeDiscrimination) {
                    if (upperCohortIds.has(attemptId) && ans.is_correct) upperCorrectCount++;
                    if (lowerCohortIds.has(attemptId) && ans.is_correct) lowerCorrectCount++;
                }

                // Distractor tracking
                const ansText = String(ans.student_answer || '').trim();
                if (ansText) {
                    optionCounts[ansText] = (optionCounts[ansText] || 0) + 1;
                }
            });

            // Difficulty Index (p) = correctCount / attemptCount
            const difficultyP = attemptCount > 0 ? (correctCount / attemptCount) : 0;
            let difficultyStatus = 'Moderate';
            let difficultyClass = 'bg-blue-100 text-blue-800 border-blue-200';

            if (difficultyP >= 0.75) {
                difficultyStatus = 'Easy';
                difficultyClass = 'bg-green-100 text-green-800 border-green-200';
            } else if (difficultyP <= 0.25) {
                difficultyStatus = 'Difficult';
                difficultyClass = 'bg-red-100 text-red-800 border-red-200';
            }

            // Discrimination Index (D) = p(upper) - p(lower)
            let discriminationD = null;
            let discriminationStatus = 'N/A';
            let discriminationClass = 'bg-gray-100 text-gray-700 border-gray-200';

            if (canComputeDiscrimination && cohortSize > 0) {
                const pUpper = upperCorrectCount / cohortSize;
                const pLower = lowerCorrectCount / cohortSize;
                discriminationD = Number((pUpper - pLower).toFixed(2));

                if (discriminationD >= 0.40) {
                    discriminationStatus = 'Very Good';
                    discriminationClass = 'bg-green-100 text-green-800 border-green-200';
                } else if (discriminationD >= 0.30) {
                    discriminationStatus = 'Good';
                    discriminationClass = 'bg-emerald-100 text-emerald-800 border-emerald-200';
                } else if (discriminationD >= 0.20) {
                    discriminationStatus = 'Fair';
                    discriminationClass = 'bg-amber-100 text-amber-800 border-amber-200';
                } else {
                    discriminationStatus = 'Poor / Defective';
                    discriminationClass = 'bg-red-100 text-red-800 border-red-200';
                }
            }

            // Multiple choice option breakdown
            const optionsBreakdown = [];
            if (q.question_type === 'multiple_choice' && Array.isArray(q.options)) {
                q.options.forEach(opt => {
                    const count = optionCounts[opt.id] || optionCounts[opt.text] || 0;
                    const pct = attemptCount > 0 ? Math.round((count / attemptCount) * 100) : 0;
                    const isKey = (opt.id.toUpperCase() === String(q.correct_answer).toUpperCase() || opt.text === q.correct_answer);
                    optionsBreakdown.push({
                        id: opt.id,
                        text: opt.text,
                        count: count,
                        percentage: pct,
                        isCorrect: isKey
                    });
                });
            }

            return {
                id: q.id,
                order_index: q.order_index || (idx + 1),
                part_label: q.part_label || null,
                question_text: q.question_text,
                question_type: q.question_type,
                correct_answer: q.correct_answer,
                points: q.points || 1,
                explanation: q.explanation || null,
                attemptsCount: attemptCount,
                correctCount: correctCount,
                difficultyP: Number(difficultyP.toFixed(2)),
                difficultyStatus: difficultyStatus,
                difficultyClass: difficultyClass,
                discriminationD: discriminationD,
                discriminationStatus: discriminationStatus,
                discriminationClass: discriminationClass,
                optionsBreakdown: optionsBreakdown
            };
        });

        // 4. Summaries and Most Missed ranking
        const validItemDiffs = items.filter(i => i.attemptsCount > 0);
        let easiestItem = null;
        let hardestItem = null;
        let avgDiff = 0;
        let avgDiscrim = 0;

        if (validItemDiffs.length > 0) {
            easiestItem = [...validItemDiffs].sort((a, b) => b.difficultyP - a.difficultyP)[0];
            hardestItem = [...validItemDiffs].sort((a, b) => a.difficultyP - b.difficultyP)[0];
            const sumP = validItemDiffs.reduce((acc, i) => acc + i.difficultyP, 0);
            avgDiff = (sumP / validItemDiffs.length).toFixed(2);

            const discrimItems = validItemDiffs.filter(i => i.discriminationD !== null);
            if (discrimItems.length > 0) {
                const sumD = discrimItems.reduce((acc, i) => acc + i.discriminationD, 0);
                avgDiscrim = (sumD / discrimItems.length).toFixed(2);
            }
        }

        const mostMissedItems = [...validItemDiffs]
            .filter(i => i.difficultyP <= 0.50)
            .sort((a, b) => a.difficultyP - b.difficultyP);

        return {
            isEmpty: false,
            totalAttempts: totalAttemptsCount,
            avgScore: avgScore,
            passingRate: passingRate,
            canComputeDiscrimination: canComputeDiscrimination,
            cohortSize: cohortSize,
            easiestItem: easiestItem,
            hardestItem: hardestItem,
            avgDifficulty: avgDiff,
            avgDiscrimination: avgDiscrim,
            mostMissedItems: mostMissedItems,
            items: items
        };
    }

    function renderItemAnalysisHTML(data) {
        if (data.isEmpty) {
            return `
                <div class="text-center py-12 px-4 bg-gray-50 border-2 border-dashed border-gray-300 rounded-2xl">
                    <div class="w-16 h-16 bg-purple-100 rounded-2xl border-2 border-ink-900 flex items-center justify-center mx-auto mb-4 text-plum-800 shadow-[3px_3px_0_0_#1c1b1a]">
                        <i class="fas fa-chart-line text-2xl"></i>
                    </div>
                    <h3 class="font-bold text-gray-800 text-lg mb-1">No Itemized Data Available</h3>
                    <p class="text-sm text-gray-500 max-w-md mx-auto">${escapeHtml(data.message)}</p>
                </div>
            `;
        }

        let html = '';

        // Summary KPI Cards
        html += `
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div class="p-4 bg-white border-2 border-ink-900 rounded-xl shadow-[3px_3px_0_0_#1c1b1a]">
                    <p class="text-xs font-bold text-gray-500 uppercase tracking-wide">Total Attempts</p>
                    <p class="text-2xl font-black text-ink-900 mt-1">${data.totalAttempts}</p>
                    <p class="text-[11px] text-gray-500 mt-0.5">${data.canComputeDiscrimination ? `Upper/Lower 27%: ${data.cohortSize} students` : 'Min 4 attempts needed for D'}</p>
                </div>
                <div class="p-4 bg-white border-2 border-ink-900 rounded-xl shadow-[3px_3px_0_0_#1c1b1a]">
                    <p class="text-xs font-bold text-gray-500 uppercase tracking-wide">Passing Rate (>=75%)</p>
                    <p class="text-2xl font-black ${data.passingRate >= 75 ? 'text-green-600' : 'text-amber-600'} mt-1">${data.passingRate}%</p>
                    <p class="text-[11px] text-gray-500 mt-0.5">Average Score: ${data.avgScore} pts</p>
                </div>
                <div class="p-4 bg-white border-2 border-ink-900 rounded-xl shadow-[3px_3px_0_0_#1c1b1a]">
                    <p class="text-xs font-bold text-gray-500 uppercase tracking-wide">Avg Difficulty (p)</p>
                    <p class="text-2xl font-black text-plum-800 mt-1">${data.avgDifficulty}</p>
                    <p class="text-[11px] text-gray-500 mt-0.5">${Number(data.avgDifficulty) >= 0.75 ? 'Easy Exam' : Number(data.avgDifficulty) <= 0.25 ? 'Challenging Exam' : 'Ideal Exam Balance'}</p>
                </div>
                <div class="p-4 bg-white border-2 border-ink-900 rounded-xl shadow-[3px_3px_0_0_#1c1b1a]">
                    <p class="text-xs font-bold text-gray-500 uppercase tracking-wide">Avg Discrimination (D)</p>
                    <p class="text-2xl font-black text-blue-700 mt-1">${data.canComputeDiscrimination ? data.avgDiscrimination : 'N/A'}</p>
                    <p class="text-[11px] text-gray-500 mt-0.5">${data.canComputeDiscrimination ? (Number(data.avgDiscrimination) >= 0.30 ? 'Good Discriminator' : 'Review Low Items') : 'Awaiting 4+ attempts'}</p>
                </div>
            </div>
        `;

        // Most Missed Questions Remediation Alert
        if (data.mostMissedItems && data.mostMissedItems.length > 0) {
            html += `
                <div class="bg-red-50/70 border-2 border-red-300 rounded-2xl p-5 shadow-[3px_3px_0_0_#ef4444]">
                    <div class="flex items-center gap-2 mb-3">
                        <i class="fas fa-exclamation-triangle text-red-600 text-lg"></i>
                        <h3 class="font-bold text-red-900 text-base">Key Focus Areas — Most Missed Questions (${data.mostMissedItems.length})</h3>
                        <span class="text-xs text-red-700 bg-red-100 px-2 py-0.5 rounded-full font-bold ml-auto">Accuracy <= 50%</span>
                    </div>
                    <p class="text-xs text-red-700 mb-4">The following questions had the lowest accuracy among students and highlight concepts for classroom reteaching:</p>
                    <div class="space-y-3">
                        ${data.mostMissedItems.slice(0, 5).map(m => `
                            <div class="p-3 bg-white rounded-xl border border-red-200 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
                                <div class="flex-1">
                                    <div class="flex items-center gap-2 mb-1">
                                        <span class="text-xs font-black px-2 py-0.5 bg-red-100 text-red-800 rounded">#${m.order_index}</span>
                                        ${m.part_label ? `<span class="text-[11px] font-bold text-gray-500"><i class="fas fa-bookmark mr-1 text-plum-800"></i>${escapeHtml(m.part_label)}</span>` : ''}
                                        <span class="text-xs font-bold text-red-600 ml-auto sm:ml-0">${Math.round(m.difficultyP * 100)}% accuracy (${m.correctCount}/${m.attemptsCount})</span>
                                    </div>
                                    <p class="text-sm font-semibold text-gray-800">${escapeHtml(m.question_text)}</p>
                                    <p class="text-xs text-gray-600 mt-1"><strong>Correct Key:</strong> <span class="text-emerald-700 font-bold">${escapeHtml(m.correct_answer)}</span></p>
                                    ${m.explanation ? `<p class="text-xs text-gray-500 italic mt-0.5"><i class="fas fa-info-circle mr-1 text-blue-500"></i>${escapeHtml(m.explanation)}</p>` : ''}
                                </div>
                            </div>
                        `).join('')}
                    </div>
                </div>
            `;
        }

        // Complete Itemized Table
        html += `
            <div class="space-y-3">
                <div class="flex items-center justify-between">
                    <h3 class="font-bold text-gray-900 text-base flex items-center gap-2">
                        <i class="fas fa-list-ol text-plum-800"></i>Itemized Questions Breakdown (${data.items.length})
                    </h3>
                    <div class="flex items-center gap-2 text-xs">
                        <span class="px-2 py-0.5 rounded-full bg-green-100 text-green-800 font-bold border border-green-200">Easy (p>=0.75)</span>
                        <span class="px-2 py-0.5 rounded-full bg-blue-100 text-blue-800 font-bold border border-blue-200">Ideal (0.26-0.74)</span>
                        <span class="px-2 py-0.5 rounded-full bg-red-100 text-red-800 font-bold border border-red-200">Hard (p<=0.25)</span>
                    </div>
                </div>

                <div class="border-2 border-ink-900 rounded-2xl overflow-hidden shadow-[4px_4px_0_0_#1c1b1a]">
                    <div class="overflow-x-auto">
                        <table class="w-full text-left text-xs border-collapse">
                            <thead class="bg-gray-100 text-gray-700 font-bold border-b-2 border-ink-900">
                                <tr>
                                    <th class="p-3 w-12 text-center">#</th>
                                    <th class="p-3 w-24">Type</th>
                                    <th class="p-3">Question Text & Key</th>
                                    <th class="p-3 w-28 text-center">Difficulty (p)</th>
                                    <th class="p-3 w-28 text-center">Discrimination (D)</th>
                                    <th class="p-3 w-24 text-center">Accuracy</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-gray-200 bg-white">
                                ${data.items.map(item => `
                                    <tr class="hover:bg-gray-50/80 transition-colors">
                                        <td class="p-3 text-center font-bold text-gray-600 align-top">${item.order_index}</td>
                                        <td class="p-3 align-top">
                                            <span class="font-bold uppercase text-[10px] px-2 py-0.5 rounded ${
                                                item.question_type === 'multiple_choice' ? 'bg-purple-100 text-purple-800'
                                                : item.question_type === 'true_false' ? 'bg-blue-100 text-blue-800'
                                                : item.question_type === 'identification' ? 'bg-amber-100 text-amber-800'
                                                : item.question_type === 'fill_in_blank' ? 'bg-emerald-100 text-emerald-800'
                                                : 'bg-cyan-100 text-cyan-800'
                                            }">
                                                ${item.question_type.replace('_', ' ')}
                                            </span>
                                            ${item.part_label ? `<p class="text-[10px] text-gray-400 mt-1 truncate max-w-[90px]"><i class="fas fa-bookmark mr-0.5"></i>${escapeHtml(item.part_label)}</p>` : ''}
                                        </td>
                                        <td class="p-3 align-top">
                                            <p class="font-semibold text-gray-900 text-sm mb-1">${escapeHtml(item.question_text)}</p>
                                            <p class="text-xs text-gray-500">
                                                <strong>Key:</strong> <span class="font-bold text-emerald-700">${escapeHtml(item.correct_answer)}</span>
                                                <span class="text-gray-300 mx-1.5">|</span>
                                                <span>${item.points} pts</span>
                                            </p>
                                            ${item.optionsBreakdown.length > 0 ? `
                                                <div class="mt-2.5 pt-2.5 border-t border-gray-100 space-y-1.5">
                                                    <p class="text-[10px] font-bold uppercase text-gray-400 tracking-wider">Distractor Distribution:</p>
                                                    <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
                                                        ${item.optionsBreakdown.map(opt => `
                                                            <div class="p-1.5 rounded-lg border ${opt.isCorrect ? 'bg-emerald-50 border-emerald-300' : 'bg-gray-50 border-gray-200'}">
                                                                <div class="flex items-center justify-between text-[11px] font-bold">
                                                                    <span class="${opt.isCorrect ? 'text-emerald-800' : 'text-gray-700'}">${escapeHtml(opt.id)}: ${escapeHtml(opt.text)}</span>
                                                                    <span class="${opt.isCorrect ? 'text-emerald-700' : 'text-gray-500'}">${opt.percentage}%</span>
                                                                </div>
                                                                <div class="w-full bg-gray-200 rounded-full h-1 mt-1 overflow-hidden">
                                                                    <div class="${opt.isCorrect ? 'bg-emerald-600' : 'bg-plum-800'} h-1 rounded-full" style="width: ${opt.percentage}%"></div>
                                                                </div>
                                                            </div>
                                                        `).join('')}
                                                    </div>
                                                </div>
                                            ` : ''}
                                        </td>
                                        <td class="p-3 text-center align-top">
                                            <p class="text-base font-black text-gray-900">${item.difficultyP}</p>
                                            <span class="inline-block mt-0.5 px-2 py-0.5 rounded-full text-[10px] font-bold border ${item.difficultyClass}">
                                                ${item.difficultyStatus}
                                            </span>
                                        </td>
                                        <td class="p-3 text-center align-top">
                                            <p class="text-base font-black ${item.discriminationD !== null ? 'text-gray-900' : 'text-gray-400'}">
                                                ${item.discriminationD !== null ? item.discriminationD : '—'}
                                            </p>
                                            <span class="inline-block mt-0.5 px-2 py-0.5 rounded-full text-[10px] font-bold border ${item.discriminationClass}">
                                                ${item.discriminationStatus}
                                            </span>
                                        </td>
                                        <td class="p-3 text-center align-top">
                                            <p class="text-sm font-bold text-gray-800">${item.correctCount}/${item.attemptsCount}</p>
                                            <p class="text-[11px] font-semibold text-gray-500">${Math.round(item.difficultyP * 100)}%</p>
                                        </td>
                                    </tr>
                                `).join('')}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        `;

        return html;
    }

    function exportItemAnalysisCSV(data, filename) {
        if (!data || !data.items || data.items.length === 0) return;

        const headers = [
            'item_number',
            'part_label',
            'question_type',
            'question_text',
            'correct_answer',
            'points',
            'total_attempts',
            'correct_attempts',
            'difficulty_index_p',
            'difficulty_status',
            'discrimination_index_d',
            'discrimination_status',
            'distractor_breakdown'
        ];

        const rows = [headers.join(',')];

        data.items.forEach(i => {
            const distractors = i.optionsBreakdown.map(o => `${o.id}: ${o.percentage}% (${o.count})`).join(' | ');
            const values = [
                i.order_index,
                i.part_label || '',
                i.question_type,
                i.question_text,
                i.correct_answer,
                i.points,
                i.attemptsCount,
                i.correctCount,
                i.difficultyP,
                i.difficultyStatus,
                i.discriminationD !== null ? i.discriminationD : '',
                i.discriminationStatus,
                distractors
            ];

            const escaped = values.map(v => {
                if (v === null || v === undefined) return '""';
                const str = String(v);
                if (str.includes(',') || str.includes('"') || str.includes('\n') || str.includes('\r')) {
                    return `"${str.replace(/"/g, '""')}"`;
                }
                return `"${str}"`;
            });
            rows.push(escaped.join(','));
        });

        const csvContent = '\uFEFF' + rows.join('\r\n');
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename || 'MathTuro_Item_Analysis.csv';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    function escapeHtml(str) {
        if (!str) return '';
        return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    window.ItemAnalysisEngine = {
        compute: computeItemAnalysis,
        renderHTML: renderItemAnalysisHTML,
        exportCSV: exportItemAnalysisCSV
    };

})(window);
